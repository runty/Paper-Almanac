import QuartzCore
import MetalKit
import OSLog

private struct PaperFrame {
    var viewport: SIMD4<Float>
    var page: SIMD4<Float>
    var hand: SIMD4<Float>
    var motion: SIMD4<Float>
    var grid: SIMD4<UInt32>
    var material: SIMD4<Float> = .zero
}

private enum PaperMetalError: Error { case unavailable }

@MainActor private final class PaperPipelines {
    static let shared: PaperPipelines? = {
        do { return try PaperPipelines() } catch {
            Logger().error("Paper pipeline initialization failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }()
    let device: MTLDevice
    let queue: MTLCommandQueue
    let fibers: MTLComputePipelineState
    let predict: MTLComputePipelineState
    let constrain: MTLComputePipelineState
    let readback: MTLComputePipelineState
    let render: MTLRenderPipelineState
    let depth: MTLDepthStencilState

    private init() throws {
        guard let gpu = MTLCreateSystemDefaultDevice(), let queue = gpu.makeCommandQueue(),
              let library = gpu.makeDefaultLibrary() else { throw PaperMetalError.unavailable }
        self.device = gpu
        self.queue = queue
        func compute(_ name: String) throws -> MTLComputePipelineState {
            guard let function = library.makeFunction(name: name) else { throw PaperMetalError.unavailable }
            return try gpu.makeComputePipelineState(function: function)
        }
        fibers = try compute("paperFibers")
        predict = try compute("paperPredict")
        constrain = try compute("paperConstrain")
        readback = try compute("paperReadback")
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "paperVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "paperFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        render = try gpu.makeRenderPipelineState(descriptor: descriptor)
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .lessEqual
        depthDescriptor.isDepthWriteEnabled = true
        guard let depth = gpu.makeDepthStencilState(descriptor: depthDescriptor) else { throw PaperMetalError.unavailable }
        self.depth = depth
    }
}

#if os(macOS)
private final class TransparentPaperView: MTKView {
    override var isOpaque: Bool { false }
}
#else
private typealias TransparentPaperView = MTKView
#endif

@MainActor final class MetalPaperScene: NSObject, MTKViewDelegate {
    private static let columns = 37
    private static let rows = 49
    private let metal: PaperPipelines
    private let rest: MTLBuffer
    private var positions: MTLBuffer
    private var scratch: MTLBuffer
    private var previous: MTLBuffer
    private let reaction: MTLBuffer
    private let joints: MTLBuffer
    private let indices: MTLBuffer
    private let indexCount: Int
    private let ink: MTLTexture
    let view: MTKView
    private var dismissSurface: (() -> Void)?
    private var displayLink: CADisplayLink?
    private var frame: PaperFrame
    private var lastTime: CFTimeInterval = 0
    private var endTime: CFTimeInterval?
    private var latestCommand: MTLCommandBuffer?
    private var soundedBonds = 0
    private var onSettled: (() -> Void)?
    private let inFlight = DispatchSemaphore(value: 2)

    static func prepare() { _ = PaperPipelines.shared }

    // ImageRenderer can return extended-range formats that MTKTextureLoader
    // cannot decode. Normalize once per grab into the shader's sRGB ink space.
    private static func printTexture(_ image: CGImage, device: MTLDevice) -> MTLTexture? {
        let width = image.width, height = image.height, stride = width * 4
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width,
                                                                  height: height, mipmapped: false)
        descriptor.usage = .shaderRead
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor),
              let color = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: stride, space: color,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let bytes = context.data else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        texture.replace(region: MTLRegionMake2D(0,0,width,height), mipmapLevel: 0, withBytes: bytes, bytesPerRow: stride)
        return texture
    }

    init?(image: CGImage, seed: UInt64, grab: CGPoint, scale: CGFloat, retainedBonds: [UInt32]?,
          canvas: CGSize, sheetOrigin: CGPoint) {
        guard let metal = PaperPipelines.shared else { return nil }
        guard let ink = Self.printTexture(image, device: metal.device) else { return nil }
        self.metal = metal
        self.ink = ink
        let width = Self.columns, height = Self.rows
        let edge = tearEdgePoints(seed: seed, width: Metrics.pageW)
        var vertices = [SIMD4<Float>]()
        var triangles = [UInt16]()
        for row in 0..<height {
            for col in 0..<width {
                let x = CGFloat(col) * Metrics.pageW / CGFloat(width - 1)
                let j = max(1, edge.firstIndex(where: { $0.x >= x }) ?? edge.count - 1)
                let a = edge[j-1], b = edge[j]
                let top = a.y + (b.y-a.y) * (x-a.x) / (b.x-a.x)
                let y = top + CGFloat(row) * (Metrics.pageH - top) / CGFloat(height - 1)
                vertices.append(SIMD4(Float(x), Float(y), 0, 1))
                if row+1 < height && col+1 < width {
                    let p = UInt16(row*width + col), q = p + UInt16(width)
                    triangles += [p,p+1,q, p+1,q+1,q]
                }
            }
        }
        func vertexBuffer() -> MTLBuffer? {
            metal.device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD4<Float>>.stride)
        }
        let intact = retainedBonds?.map { UInt32($0 == 1 ? 1 : 0) } ?? [UInt32](repeating: 0, count: width)
        soundedBonds = intact.filter { $0 != 0 }.count
        guard let rest = vertexBuffer(), let pos = vertexBuffer(), let prev = vertexBuffer(), let tmp = vertexBuffer(),
              let reaction = metal.device.makeBuffer(bytes: [SIMD4<Float>](repeating: .zero, count: width),
                                                      length: width * MemoryLayout<SIMD4<Float>>.stride),
              let bonds = metal.device.makeBuffer(bytes: intact, length: width * MemoryLayout<UInt32>.stride),
              let indices = metal.device.makeBuffer(bytes: triangles, length: triangles.count * MemoryLayout<UInt16>.stride)
        else { return nil }
        self.rest = rest
        positions = pos
        previous = prev
        scratch = tmp
        self.reaction = reaction
        joints = bonds
        self.indices = indices
        indexCount = triangles.count

        view = TransparentPaperView(frame: CGRect(origin: .zero, size: canvas), device: metal.device)
        frame = PaperFrame(viewport: .init(Float(canvas.width), Float(canvas.height), Float(sheetOrigin.x), Float(sheetOrigin.y)),
                           page: .init(Float(Metrics.pageW), Float(Metrics.pageH), Float(scale), 1/120),
                           hand: .init(Float(grab.x), Float(grab.y), 0, 0), motion: .zero,
                           grid: .init(UInt32(width), UInt32(height), 0, 0))
        super.init()
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        #if os(iOS)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.layer.isOpaque = false
        view.isUserInteractionEnabled = false
        #else
        view.layer?.isOpaque = false
        #endif
        view.delegate = self
    }

    func start(dismissSurface: @escaping () -> Void) {
        self.dismissSurface = dismissSurface
        lastTime = CACurrentMediaTime()
        #if os(macOS)
        let link = view.displayLink(target: self, selector: #selector(tick))
        #else
        let link = CADisplayLink(target: self, selector: #selector(tick))
        #endif
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    // A lift into the sheet uses up free paper before loading the binding.
    // Grabbing nearer the binding shortens that free span. A crosswise pull
    // can load it in shear while the lower part of the sheet is still folded.
    static func tension(at grab: CGPoint, pull: CGSize) -> CGFloat {
        let span = max(0, grab.y - Metrics.tearY)
        let crosswise = max(0, abs(pull.width) - min(32, span * 0.09)) * 1.22
        // Moving the grip toward the binding shortens the end-to-end
        // distance. Even after it passes the strip the folded sheet has
        // slack until that distance exceeds the original free length.
        let extensionAlongSheet = max(0, abs(span + pull.height) - span)
        return hypot(crosswise, extensionAlongSheet)
    }

    func pull(_ translation: CGSize, loadsBinding: Bool = true) {
        frame.hand.z = Float(translation.width)
        frame.hand.w = Float(translation.height)
        frame.material.x = loadsBinding ? Float(Self.tension(at: CGPoint(x: CGFloat(frame.hand.x), y: CGFloat(frame.hand.y)),
                                              pull: translation)) : 0
    }

    func bindingState() -> [UInt32] {
        latestCommand?.waitUntilCompleted()
        let pointer = joints.contents().bindMemory(to: UInt32.self, capacity: Self.columns)
        return Array(UnsafeBufferPointer(start: pointer, count: Self.columns))
    }

    func canDetach(with bonds: [UInt32]) -> Bool {
        bonds.allSatisfy { $0 == 1 }
    }

    func settle(completion: @escaping () -> Void) {
        frame.motion = .init(1,0,0,0)
        endTime = CACurrentMediaTime() + 2.5
        onSettled = completion
    }

    func drop(velocity: CGSize, completion: (() -> Void)? = nil) {
        // Release can arrive before the last GPU report reaches the main actor.
        soundBrokenBonds(Self.columns)
        onSettled = completion
        frame.motion = .init(2, Float(650*tanh(velocity.width/800)), Float(750*tanh(velocity.height/900)), 1)
        endTime = CACurrentMediaTime() + Double((frame.viewport.y-frame.viewport.w)/(frame.page.z*580)) + 2
    }

    func close() {
        displayLink?.invalidate()
        displayLink = nil
        view.delegate = nil
        dismissSurface?()
        dismissSurface = nil
        let completion = onSettled
        onSettled = nil
        completion?()
    }

    @objc private func tick() {
        if let endTime, CACurrentMediaTime() >= endTime { close(); return }
        view.draw()
    }

    private func received(_ sample: SIMD4<Float>) {
        guard displayLink != nil, sample.z == frame.motion.x else { return }
        if frame.motion.x == 1 && sample.y < 0.65 { close(); return }
        if frame.motion.x == 0 { soundBrokenBonds(Int(sample.x)) }
    }

    private func soundBrokenBonds(_ broken: Int) {
        guard broken > soundedBonds else { return }
        if broken == Self.columns {
            soundedBonds = broken
            TearSound.shared.playRip()
            Haptics.rip()
        } else if soundedBonds == 0 || broken - soundedBonds >= 7 {
            soundedBonds = broken
            Haptics.tick()
            TearSound.shared.playCrackle(intensity: Float(broken)/Float(Self.columns))
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let pass = view.currentRenderPassDescriptor,
              let command = metal.queue.makeCommandBuffer(), inFlight.wait(timeout: .now()) == .success else { return }
        let slots = inFlight
        let report = metal.device.makeBuffer(length: MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)
        command.addCompletedHandler { [weak self] buffer in
            slots.signal()
            guard buffer.status == .completed, let report else { return }
            let sample = report.contents().load(as: SIMD4<Float>.self)
            Task { @MainActor [weak self] in self?.received(sample) }
        }
        let now = CACurrentMediaTime()
        let count = min(4, max(1, Int(((now-lastTime)*120).rounded())))
        lastTime = now
        if let compute = command.makeComputeCommandEncoder() {
            func dispatch(_ pipeline: MTLComputePipelineState, _ buffers: [MTLBuffer], _ threads: Int) {
                compute.setComputePipelineState(pipeline)
                for (i, buffer) in buffers.enumerated() { compute.setBuffer(buffer, offset: 0, index: i) }
                compute.setBytes(&frame, length: MemoryLayout<PaperFrame>.stride, index: buffers.count)
                compute.dispatchThreads(.init(width: threads, height: 1, depth: 1),
                                        threadsPerThreadgroup: .init(width: min(threads,64), height: 1, depth: 1))
                compute.memoryBarrier(scope: .buffers)
            }
            let n = Self.columns * Self.rows
            for _ in 0..<count {
                if frame.motion.x == 0 { dispatch(metal.fibers,[rest,reaction,joints],1) }
                dispatch(metal.predict,[rest,positions,previous,scratch],n)
                swap(&previous,&positions)
                swap(&positions,&scratch)
                frame.motion.w = 0
                for _ in 0..<9 {
                    dispatch(metal.constrain,[rest,positions,scratch,joints,reaction],n)
                    swap(&positions,&scratch)
                }
            }
            if let report { dispatch(metal.readback, [joints,positions,rest,report], 1) }
            compute.endEncoding()
        }
        if let draw = command.makeRenderCommandEncoder(descriptor: pass) {
            draw.setRenderPipelineState(metal.render)
            draw.setDepthStencilState(metal.depth)
            draw.setCullMode(.none)
            draw.setFrontFacing(.clockwise)
            draw.setVertexBuffer(positions, offset: 0, index: 0)
            draw.setVertexBuffer(rest, offset: 0, index: 1)
            draw.setVertexBytes(&frame, length: MemoryLayout<PaperFrame>.stride, index: 2)
            draw.setFragmentTexture(ink, index: 0)
            for value: UInt32 in [1,0] {
                var shadow = value
                draw.setVertexBytes(&shadow, length: 4, index: 3)
                draw.setFragmentBytes(&shadow, length: 4, index: 0)
                draw.drawIndexedPrimitives(type: .triangle, indexCount: indexCount,
                                           indexType: .uint16, indexBuffer: indices, indexBufferOffset: 0)
            }
            draw.endEncoding()
        }
        command.present(drawable)
        command.commit()
        latestCommand = command
    }
}
