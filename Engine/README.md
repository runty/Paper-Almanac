# Paper Almanac daily engine

This local Swift package exposes the `TungShingDailyAlmanac` product. It supplies offline day reports, solar terms, Celestial Almanac annotations, Fuji holidays, and Japanese calendar readings for Rekichū and Tsukigoyomi. The source was extracted from the engine revision `3fa6e7899d839aa39900510c963b062b29a854ca` with the six targets used by the daily product. The package carries the daily runtime tables and their provenance. The source revision and research paths in the provenance identify records in the development archive.

For Rekichū and Tsukigoyomi, `CelestialTraditions` supplies Rokuyō and the tide class for the Japanese old-calendar day, plus the Japanese character for the day’s mansion. `CelestialSky.lunarAgeAtJapaneseNoon(on:)` returns the elapsed days since the most recent conjunction at 12:00 JST (03:00 UTC). The page rounds this value to one decimal place.

For Tsukigoyomi, `JapaneseSeason(on:)` looks up the solar term and microseason for a Japanese civil date. The table covers the app’s 1901–2100 date range. `CelestialSky.atJapaneseNoon(on:)` supplies the matching lunar illumination and waxing or waning direction.

To regenerate the bundled start dates, install Skyfield 1.55 and NumPy and run `python3 scripts/build_japanese_microseasons.py /path/to/de440s.bsp` from the repository root with the JPL DE440s kernel. The script validates the kernel checksum. App and widget builds read the checked-in table directly.

The source follows the repository's MIT license, with separately licensed data as described in the bundled notices. [MIT License](../LICENSE) · [Engine notices](Sources/TungShingDailyAlmanac/Resources/THIRD_PARTY_NOTICES.txt) · [Provenance](Sources/TungShingDailyAlmanac/Resources/PROVENANCE.json)
