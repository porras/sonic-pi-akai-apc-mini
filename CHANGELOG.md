# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `set_trigger` and `reset_trigger` methods
- Reversed ranges (they already worked but that was an undocumented feature, now
  it's part of the API)
- `release` option for `free_play`

### Changed

- After a refactor, the behavior and signature of `free_play` and
  `reset_free_play` changed. See README.md
- General performance and stability improvement, through a couple of refactors:
  - The aforementioned rewrite of `free_play`.
  - An utility class that keeps track of the current state of the lights panel
    and avoids unnecessary updates.

### Fixed

- More than a bug it was a "known annoying behavior": because of the way `sync`
  works, whenever we would redefine a trigger or free play, we would still react
  with the old definition to the next event, and _then_ reload it. I implemented
  a workaround so that it behaves in a more intuitive way: the next event will
  already trigger the new definition.

### Removed

- An extension to `Range` that was no longer in use since a refactor long ago.

### Other

- Extracted `fake_sonic_pi` to a separate gem.

## [0.3.0] - 2022-02-10

### Added 

- This CHANGELOG ;)
- `set_fader` method

### Other

- Integration specs for fader related methods

## [0.2.0] - 2022-01-29

### Added

- Experimental support for APC Key 25
- `example.rb`

### Changed

- The `initialize_akai` method now requires the model name (`:apc_mini` or
  `:apc_key_25`) as argument.

### Other

- `init_dev.rb` helper to work on development
- Some unit specs (grid mapping logic)

## [0.1.0] - 2022-01-09

Initial release.

[unreleased]: https://github.com/porras/sonic-pi-akai-apc-mini/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/porras/sonic-pi-akai-apc-mini/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/porras/sonic-pi-akai-apc-mini/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/porras/sonic-pi-akai-apc-mini/releases/tag/v0.1.0
