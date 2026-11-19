# Notices for TungShingCore

## Historical clock before 1972 (S15.2020)

`HistoricalUT1.swift` carries the nineteen 1895–1974 segments of Table S15.2020, the cubic spline of ΔT
(TT − UT1) in L. V. Morrison, F. R. Stephenson, C. Y. Hohenkerk and M. Zawilski, Addendum 2020 to
"Measurement of the Earth's rotation: 720 BC to AD 2015", supplementary dataset version 2,
doi:10.6084/m9.figshare.13885863.v2 (https://rs.figshare.com/articles/dataset/13885863/2).
Licence: Creative Commons Attribution 4.0 International (https://creativecommons.org/licenses/by/4.0/).

Modification notice: the coefficients are the binary64 values that Skyfield 1.55 stores, which truncate
the spline where Skyfield's daily table begins and adjust the 1971–1974 segment's linear coefficient
(printed 3.157, stored 3.4897025899490037). They were taken from the research reference
`tung-shing-research/docs/handoff/calendar-pack/review/ut1-historical-clock/COEFFICIENTS.json` at commit
`21568ea8b4286d4772a9ef989366f2bec937eb39` (profile `HK8-S15-SKYFIELD155-REAL-UT1-1972-UTC-v1`). The
research does not certify the model's physical accuracy; the app treats it as a named convention with a
stated time budget.

## Skyfield 1.55

https://github.com/skyfielders/python-skyfield/tree/1.55

```text
Copyright © 2013–2018 Brandon Rhodes and available under the MIT license:

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
