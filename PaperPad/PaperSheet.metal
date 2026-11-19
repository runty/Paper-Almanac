#include <metal_stdlib>
using namespace metal;

// Positions are in page points. Positive z comes out of the pad toward the hand.
struct Frame {
    float4 viewport; // width, height, paper origin x, y (window points)
    float4 page;     // width, height, scale, timestep
    float4 hand;     // grab xy, translation xy
    float4 motion;   // mode (held, settling, free), release velocity xy, first free step
    uint4 grid;
    float4 material; // applied tension in points after the slack is taken up
};
static uint indexAt(int2 p, constant Frame &f) {
    return uint(clamp(p.y, 0, int(f.grid.y)-1)) * f.grid.x + uint(clamp(p.x, 0, int(f.grid.x)-1));
}
static float3 normalAt(device const float4 *p, int2 ij, constant Frame &f) {
    float3 du = p[indexAt(ij+int2(1,0),f)].xyz - p[indexAt(ij-int2(1,0),f)].xyz;
    float3 dv = p[indexAt(ij+int2(0,1),f)].xyz - p[indexAt(ij-int2(0,1),f)].xyz;
    float3 n = cross(du,dv);
    return n * rsqrt(max(dot(n,n), 1.e-8));
}

// A fingertip turns the local tangent as it lifts an edge. Transport the paper
// around a cylindrical grip, then let the distance constraints transmit the bend.
static float3 gripPose(float3 rest, constant Frame &f) {
    float2 grab = f.hand.xy, pull = f.hand.zw;
    float side = grab.x < f.page.x * .5 ? 1. : -1.;
    // Lifting one corner twists the bend axis toward the free edge. A grip
    // at the middle lifts both lower corners together.
    float eccentricity = abs(2.*grab.x/f.page.x - 1.);
    float twist = max(-pull.y,0.) * .52 * eccentricity;
    float2 inward = float2(side * max(side * pull.x,twist), min(pull.y,0.));
    float travel = length(inward);
    float3 target = rest;
    if (travel > .01) {
        float2 n = inward / travel;
        float radius = min(35., travel * .27);
        float angle = 2.32;
        float crease = (travel + radius * (sin(angle) - angle*cos(angle))) / (1.-cos(angle));
        float d = dot(rest.xy - grab,n);
        float arc = max(crease-d,0.);
        float theta = min(arc/radius,angle);
        float flat = max(arc-radius*angle,0.);
        target.xy += n * (arc - radius*sin(theta) - flat*cos(theta));
        target.z += radius*(1.-cos(theta)) + flat*sin(theta);
    }
    float influence = exp(-distance(rest.xy,grab)/150.);
    target.xy += (pull-inward) * influence;
    target.z += min(length(pull)*.18,22.) * influence;
    return target;
}

// The fixed header and the moving mesh meet at one joint per column.
// The constraint solver measures the force needed to keep each joint in
// place. Newly exposed fibers see the redistributed load on the next step.
kernel void paperFibers(device const float4 *rest [[buffer(0)]],
                        device const float4 *reaction [[buffer(1)]],
                        device uint *broken [[buffer(2)]], constant Frame &f [[buffer(3)]],
                        uint id [[thread_position_in_grid]]) {
    if (id || f.motion.x != 0.) return;
    uint width = f.grid.x, remaining=0;
    int tip=-1;
    float highest=1.;
    for (uint i=0; i<width; ++i) {
        if (broken[i]==1) continue;
        ++remaining;
        bool neighbor=(i>0 && broken[i-1]==1) || (i+1<width && broken[i+1]==1);
        float3 load=reaction[i].xyz;
        // Peeling and shearing load the joint. Compression into the binding
        // cannot open it. Edge fibers have support on only one side.
        float compression=max(-load.y,0.) + max(-load.z,0.);
        float shear=max(0.,abs(load.x)-.3*compression);
        float traction=length(float3(shear,max(load.y,0.),max(load.z,0.)));
        float strength=(neighbor ? .68 : 1.) * ((i==0 || i+1==width) ? .82 : 1.);
        float stripLength=distance(rest[i+width].xyz,rest[i].xyz);
        float strainRatio=traction/(.0152 * stripLength * strength);
        if (strainRatio>highest) { highest=strainRatio; tip=int(i); }
    }
    if (tip>=0 && f.material.x>=14.) {
        broken[tip]=1;
        // Once the penultimate fiber parts under load, the unsupported final
        // sliver goes with it. The hand still holds the loose sheet.
        if (remaining==2)
            for (uint i=0; i<width; ++i) broken[i]=1;
    }
}

kernel void paperPredict(device const float4 *rest [[buffer(0)]], device const float4 *pos [[buffer(1)]],
                         device const float4 *previous [[buffer(2)]], device float4 *out [[buffer(3)]],
                         constant Frame &f [[buffer(4)]],
                         uint i [[thread_position_in_grid]]) {
    if (i >= f.grid.x*f.grid.y) return;
    int2 ij=int2(i%f.grid.x,i/f.grid.x);
    float dt=f.page.w;
    float3 p=pos[i].xyz, v=(p-previous[i].xyz)/dt;
    // Internal damping acts on relative velocity. A rigid translation or
    // rotation is preserved, while neighboring fibers resist local flutter.
    float3 damping=0;
    float samples=0;
    for (int axis=0;axis<2;++axis) {
        int2 dir=axis==0 ? int2(2,0) : int2(0,2);
        if (any(ij-dir<0) || any(ij+dir>=int2(f.grid.xy))) continue;
        uint lo=indexAt(ij-dir,f), hi=indexAt(ij+dir,f);
        float3 average=(pos[lo].xyz-previous[lo].xyz + pos[hi].xyz-previous[hi].xyz)/ (2.*dt);
        damping+=average-v;
        samples+=1.;
    }
    v+=.38*damping/max(samples,1.);
    float3 r=rest[i].xyz;
    bool free=f.motion.x==2.;
    float3 a=float3(0,free ? 1570. : 180.,0);
    if (free) {
        if (f.motion.w>0.) v += float3(f.motion.yz,0) * (.20 + .48*exp(-distance(r.xy,f.hand.xy)/115.));
        float3 n=normalAt(pos,ij,f);
        float vn=dot(v,n);
        // Broadside paper catches air; edge-on paper cuts through it.
        a -= .0032*vn*abs(vn)*n;
        v *= exp(-.40*dt);
    } else if (f.motion.x==1.) {
        // The intact hinge takes the weight. As the lifted corner loses
        // height, the wall catches it and air damps the last oscillation.
        a = (r-p)*67. + float3(0,185.,-92.)*saturate(p.z/22.);
        v *= exp(-7.5*dt);
    } else {
        v *= exp(-9.*dt);
        float3 handle=gripPose(r,f);
        float range=distance(r.xy,f.hand.xy);
        float lifted=saturate((handle.z-2.)/24.);
        a += (handle-p)*(30. + 185.*lifted + 340.*exp(-range/42.));

    }
    float3 next=p + clamp(v,float3(-2500),float3(2500))*dt + a*dt*dt;
    next.z=max(0.,next.z);
    out[i]=float4(next,1);
}

constant int2 links[] = { int2(1,0),int2(-1,0),int2(0,1),int2(0,-1),
    int2(1,1),int2(-1,-1),int2(1,-1),int2(-1,1),int2(3,0),int2(-3,0),int2(0,3),int2(0,-3) };
kernel void paperConstrain(device const float4 *rest [[buffer(0)]], device const float4 *pos [[buffer(1)]],
                           device float4 *out [[buffer(2)]], device const uint *broken [[buffer(3)]],
                           device float4 *reaction [[buffer(4)]], constant Frame &f [[buffer(5)]], uint i [[thread_position_in_grid]]) {
    if (i>=f.grid.x*f.grid.y) return;
    int2 ij=int2(i%f.grid.x,i/f.grid.x);
    float3 r=rest[i].xyz, p=pos[i].xyz;
    bool held=f.motion.x==0.;
    float3 correction=0;
    float weights=0;
    for (int k=0;k<12;++k) {
        int2 neighbor=ij+links[k];
        if (any(neighbor<0) || any(neighbor>=int2(f.grid.xy))) continue;
        uint j=indexAt(neighbor,f);
        float3 delta=pos[j].xyz-p;
        float len=max(length(delta),.001);
        float weight=k<4 ? 1. : (k<8 ? .80 : .42);
        correction+=weight * delta * (1.-distance(r,rest[j].xyz)/len);
        weights+=weight;
    }
    p += .91*correction/max(weights,1.);
    // Flexural stiffness. The second difference resists a sharp kink while
    // the shorter structural and diagonal fibers resist stretch and shear.
    for (int axis=0;axis<2;++axis) {
        int2 dir=axis==0 ? int2(2,0) : int2(0,2);
        if (any(ij-dir<0) || any(ij+dir>=int2(f.grid.xy))) continue;
        uint l=indexAt(ij-dir,f), h=indexAt(ij+dir,f);
        p += .095*((pos[l].xyz+pos[h].xyz)*.5-pos[i].xyz -
                   ((rest[l].xyz+rest[h].xyz)*.5-r));
    }
    // Discrete thin-plate bending. Penalize fast changes in curvature across
    // both short and longer spans, while allowing a broad cylindrical fold.
    for (int axis=0;axis<2;++axis) {
        for (int span=1;span<=3;span+=2) {
            int2 dir=axis==0 ? int2(span,0) : int2(0,span);
            if (any(ij-2*dir<0) || any(ij+2*dir>=int2(f.grid.xy))) continue;
            uint a=indexAt(ij-2*dir,f), b=indexAt(ij-dir,f), c=indexAt(ij+dir,f), d=indexAt(ij+2*dir,f);
            float3 curvatureChange=(pos[a].xyz-rest[a].xyz)+(pos[d].xyz-rest[d].xyz)
                -4.*((pos[b].xyz-rest[b].xyz)+(pos[c].xyz-rest[c].xyz))+6.*(pos[i].xyz-r);
            p-=(span==1 ? .022 : .014)*curvatureChange;
        }
    }
    if (held) {
        float grip=exp(-dot(r.xy-f.hand.xy,r.xy-f.hand.xy)/150.);
        // Constrain the grip in camera space so its ink stays under the cursor.
        float3 goal=gripPose(r,f);
        float2 screen=r.xy+f.hand.zw;
        goal.xy=f.page.xy*.5 + (screen-f.page.xy*.5)*(1.-goal.z/1500.);
        p=mix(p,goal,.70*grip);
    }
    if (ij.y==0 && f.motion.x!=2. && broken[ij.x]!=1) {
        float3 displacement=p-r;
        // Reaction of the binding spring, before enforcing its rest length.
        reaction[ij.x]=float4(mix(reaction[ij.x].xyz,displacement,.21),0);
        p=r+displacement*.10;
    }
    out[i]=float4(p.xy,max(p.z,0.),1);
}

// Compact readback for feedback and settling. State changes are reported
// only after the GPU has completed the corresponding simulation step.
kernel void paperReadback(device const uint *broken [[buffer(0)]], device const float4 *pos [[buffer(1)]],
                          device const float4 *rest [[buffer(2)]], device float4 *result [[buffer(3)]],
                          constant Frame &f [[buffer(4)]], uint id [[thread_position_in_grid]]) {
    if (id) return;
    uint count=0;
    for (uint i=0; i<f.grid.x; ++i) count+=(broken[i]==1);
    float error=0;
    if (f.motion.x==1.)
        for (uint i=0; i<f.grid.x*f.grid.y; ++i)
            error=max(error,distance(pos[i].xyz,rest[i].xyz));
    result[0]=float4(float(count),error,f.motion.x,pos[(f.grid.x*f.grid.y)/2].y);
}

struct Surface {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float height;
};
vertex Surface paperVertex(uint i [[vertex_id]], device const float4 *pos [[buffer(0)]],
                           device const float4 *rest [[buffer(1)]], constant Frame &f [[buffer(2)]],
                           constant uint &shadow [[buffer(3)]]) {
    int2 ij=int2(i%f.grid.x,i/f.grid.x);
    float3 p=pos[i].xyz;
    float w=clamp(1.-p.z/1500.,.5,1.4);
    float2 xy=f.page.xy*.5 + (p.xy-f.page.xy*.5)/w;
    if (shadow) { xy=p.xy+float2(.28,.38)*p.z; w=1.; }
    float2 screen=f.viewport.zw+xy*f.page.z;
    float2 clip=screen/f.viewport.xy*float2(2.,-2.)+float2(-1.,1.);
    float depth=shadow ? .99 : clamp(.86-p.z/1200.,.01,.95);
    return {float4(clip*w,depth*w,w),normalAt(pos,ij,f),rest[i].xy/f.page.xy,p.z};
}
fragment half4 paperFragment(Surface s [[stage_in]], bool front [[front_facing]],
                             texture2d<float> print [[texture(0)]], constant uint &shadow [[buffer(0)]],
                             constant float3 &stock [[buffer(1)]]) {
    if (shadow) {
        half alpha=half(.065+.105*exp(-s.height/55.));
        return half4(0,0,0,alpha);
    }
    constexpr sampler inkSampler(coord::normalized, address::clamp_to_edge, filter::linear);
    float3 ink=print.sample(inkSampler,s.uv).rgb;
    float3 n=normalize(front ? s.normal : -s.normal);
    float diffuse=dot(n,normalize(float3(-.38,-.48,.79)));
    float light=clamp(.72+.35*diffuse,.50,1.04);
    float3 paper=front ? ink : mix(stock,ink,.075);
    return half4(half3(paper*light),1);
}
