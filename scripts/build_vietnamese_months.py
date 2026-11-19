"""Generate modern UTC+7 Vietnamese lunar months with Skyfield 1.55 and JPL DE440s."""
import argparse
from bisect import bisect_left, bisect_right
from datetime import date
from hashlib import sha256
import json
from pathlib import Path

import numpy as np
from skyfield.api import load, load_file
from skyfield.framelib import ecliptic_frame


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kernel", type=Path)
    kernel = parser.parse_args().kernel
    if sha256(kernel.read_bytes()).hexdigest() != "c1c7feeab882263fc493a9d5a5b2ddd71b54826cdf65d8d17a76126b260a49f2":
        raise ValueError("Expected the DE440s short kernel")
    eph = load_file(str(kernel))
    ts = load.timescale(builtin=True)
    epoch = date(1970, 1, 1)
    moons, terms, solstices = [], [], []
    last_angle, last_term = None, None
    for year in range(1899, 2103):
        first = date(year, 1, 1)
        days = (date(year + 1, 1, 1) - first).days
        # Evaluate immediately before midnight in Vietnam. A crossing belongs
        # to its entire local calendar day, including when two events coincide.
        t = ts.utc(year, 1, np.arange(1, days + 1), 16, 59, 59.999)
        earth = eph["earth"].at(t)
        sun = earth.observe(eph["sun"]).apparent().frame_latlon(ecliptic_frame)[1].degrees
        moon = earth.observe(eph["moon"]).apparent().frame_latlon(ecliptic_frame)[1].degrees
        for offset, (angle, term) in enumerate(zip((moon - sun) % 360, (sun // 30).astype(int))):
            day = (first - epoch).days + offset
            if last_angle is not None and angle < last_angle:
                moons.append(day)
            if last_term is not None and term != last_term:
                terms.append(day)
                if term == 9:
                    solstices.append((year, day))
            last_angle, last_term = angle, term

    rows = []
    for (year, winter), (_, next_winter) in zip(solstices, solstices[1:]):
        start, end = (bisect_right(moons, day) - 1 for day in (winter, next_winter))
        assert end - start in (12, 13)
        leap = None
        if end - start == 13:
            leap = next(i for i in range(start + 1, end)
                        if bisect_left(terms, moons[i]) == bisect_left(terms, moons[i + 1]))
        number, lunar_year = 11, year
        for i in range(start, end):
            if i != start and i != leap:
                number = number % 12 + 1
                if number == 1:
                    lunar_year += 1
            rows.append([moons[i], lunar_year, -number if i == leap else number])
    assert all(b[0] - a[0] in (29, 30) for a, b in zip(rows, rows[1:]))
    assert rows[0][0] <= (date(1901, 1, 1) - epoch).days
    assert rows[-1][0] > (date(2100, 12, 31) - epoch).days
    root = Path(__file__).resolve().parents[1]
    output = root / "Engine/Sources/TungShingDailyAlmanac/Resources/vietnamese-months.json"
    output.write_text(json.dumps(rows, separators=(",", ":")) + "\n")


if __name__ == "__main__":
    main()
