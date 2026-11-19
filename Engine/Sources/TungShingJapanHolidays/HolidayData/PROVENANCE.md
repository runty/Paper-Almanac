# Shared Japanese national holiday provider

`JapanHolidays.swift` is the unchanged previously admitted regional implementation. The separate target
allows `TungShingDailyAlmanac` to use that same implementation and table without linking other regional
providers or assets. `TungShingRegional` re-exports the API for its existing consumers.

`JP_RUNTIME_DATA.json` is the byte-identical previously admitted table, SHA-256
`147a8cd38f097c8c5319fb4342f57e143bf9cbda7df5d4090295f8d896ddfe7b`.
Research repository: `https://github.com/runty/tung-shing-research`; source path:
`docs/handoff/extensions/regional-holidays-jp-1/RUNTIME_DATA.json`; candidate commit:
`81f5d301a780316c248b44d8a768ef5b6c28e384`; acceptance: `e3eb3f81f236facfa672472d34ebf59922c63ee4`,
`docs/handoff/extensions/accepted/regional-holidays-jp-1/DECISION.json`.
The existing `research.lock.json` and `Tools/research-intake/copy_extension_assets.py` retain the intake
pins; only the runtime destination changed. No date, holiday name, kind, profile or coverage changed.

Source: Cabinet Office, Government of Japan, “国民の祝日について”,
https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html. The table contains national, substitute and citizens'
holidays and special acts for 1955–2027, with source names verbatim. Reuse: Public Data License
(Version 1.0), compatible with CC BY 4.0. Changes from the source: normalization and classification.
No Cabinet Office endorsement is implied. Attribution is in the table and in the daily product's
`THIRD_PARTY_NOTICES.txt`; the broad app preserves its existing `RegionalHolidaysJP1/NOTICE.txt`.
