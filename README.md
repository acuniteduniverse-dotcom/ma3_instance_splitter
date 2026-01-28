# grandMA3 Instance Splitter

A free grandMA3 Lua plugin that creates clean, predictable groups from
fixtures with subfixtures and pixel structures.

Supports:
- Fixtures
- Fixture.Sub
- Fixture.Sub.Pixel
- Compact MA3 selection syntax

This tool is designed for real-world rigs where fixture instances and
pixel layouts vary.

---

## Features

- User-defined block system
- Depth-aware grouping (1 / 2 / 3)
- Safe naming with prefix
- Overwrite / Merge selection
- Optional ALL HEADS group
- Uses MA3-supported compact selection syntax

Example:
Fixture 901 Thru 903.1 Thru 2.1 Thru 999

yaml
Copy code

---

## Installation

1. Download `Instance_Splitter.lua`
2. Copy to your showfile or user plugins folder
3. Import as a plugin in grandMA3
4. Run from Plugin Pool

---

## Compatibility

- grandMA3 v2.3+
- Tested on real pixel + multi-instance fixtures

---

## Why this is free

This plugin is released free to support the MA community and establish
a foundation for future advanced tools.

If you find it useful, please star the repo or share it.

---

## License

MIT License — free to use, modify, and share.
