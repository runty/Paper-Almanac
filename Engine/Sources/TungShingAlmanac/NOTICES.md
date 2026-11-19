# Third-party notices for TungShingAlmanac

The `TungShingAlmanac` target is a Swift port of the almanac evaluator and its tables from
**OPN48/cnlunar**, pinned at commit `3f674fe0f458b480c79eaaf5464f43f4bc815a91`
(https://github.com/OPN48/cnlunar). The ported files are `cnlunar/lunar.py`,
`cnlunar/config.py`, `cnlunar/solar24.py`, `cnlunar/tools.py` and `cnlunar/holidays.py`.
Source Simplified Chinese tokens are retained as stable identifiers.

The upstream code license follows. Provenance of data embedded upstream (for example calendar
tables credited to the Hong Kong Observatory) is a separate review item and is not covered by
this code license; see `docs/design/PHASE_2_ALMANAC.md`.

```text
MIT License

Copyright (c) 2025 OPN48

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Upstream credits earlier implementations (Yovey, Late Lee, Chen Jian) in `lunar.py`'s header;
those credits are reproduced here by reference.
