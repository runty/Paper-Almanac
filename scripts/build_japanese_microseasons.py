"""Generate offline Japanese civil start dates. Requires Skyfield 1.55 and JPL de440s.bsp."""
import argparse
from datetime import date, timedelta
from hashlib import sha256
import json
from pathlib import Path

import numpy as np
from skyfield.api import load, load_file
from skyfield.framelib import ecliptic_frame


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kernel", type=Path)
    args = parser.parse_args()
    if sha256(args.kernel.read_bytes()).hexdigest() != "c1c7feeab882263fc493a9d5a5b2ddd71b54826cdf65d8d17a76126b260a49f2":
        raise ValueError("Expected the DE440s short kernel")
    eph = load_file(str(args.kernel))
    ts = load.timescale(builtin=True)
    epoch = date(1970, 1, 1)
    starts = []
    previous = None
    for year in range(1900, 2101):
        first = date(year, 1, 1)
        days = (date(year + 1, 1, 1) - first).days
        # The entire Japanese civil date takes the season reached just before
        # the next midnight (15:00 UTC). Seasons advance every five degrees.
        t = ts.utc(year, 1, np.arange(1, days + 1), 14, 59, 59.999)
        sun = eph["earth"].at(t).observe(eph["sun"]).apparent()
        longitude = sun.frame_latlon(ecliptic_frame)[1].degrees
        sectors = ((longitude - 315) % 360 // 5).astype(int)
        for offset, sector in enumerate(sectors):
            if sector != previous and (starts or sector == 0):
                assert sector == len(starts) % 72
                starts.append((first + timedelta(days=offset) - epoch).days)
            previous = sector
    assert all(4 <= b - a <= 6 for a, b in zip(starts, starts[1:]))
    root = Path(__file__).resolve().parents[1]
    path = root / "Engine/Sources/TungShingDailyAlmanac/Resources/japanese-microseason-starts.json"
    path.write_text(json.dumps(starts, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    main()
