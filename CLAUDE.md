# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests
bundle exec rspec

# Run a single spec file
bundle exec rspec spec/localio_spec.rb

# Run a single example by line number
bundle exec rspec spec/localio_spec.rb:42

# Standard gem tasks (build, install, release)
bundle exec rake
```

## What This Gem Does

Localio reads translation data from spreadsheets (Google Drive, XLS, XLSX, CSV) and generates platform-specific localization files. Supported output platforms: Android (`strings.xml`), iOS/Swift (`.strings` + header/constants), JSON, Rails YAML, Java `.properties`, `.resx`, and Twine format.

The entry point is `bin/localize`, which reads a `Locfile` (Ruby DSL) from the current directory.

## Architecture

### Data Flow

```
Locfile (DSL config)
  → Processor (reads spreadsheet source)
  → Filter (regex-based key filtering)
  → LocalizableWriter (dispatches to platform writer)
  → ERB templates → output files
```

### Key Abstractions

**`Locfile`** (`lib/localio/locfile.rb`) — DSL parser using `instance_eval`. Stores platform, source credentials, output path, formatter, and filters.

**`Processor`** (`lib/localio/processor.rb`) — Routes to the correct reader based on `:platform` config. Returns a hash of `language => [Segment]` pairs.

**`LocalizableWriter`** (`lib/localio/localizable_writer.rb`) — Routes to the correct writer class. Writers live in `lib/localio/writers/` and use ERB templates from `lib/localio/templates/`.

**`Segment`** — A single translation unit: `{key, value, language}`. **`Term`** — A key with a hash of all language values.

**`Filter`** (`lib/localio/filter.rb`) — Applied after loading; supports `:only` (allowlist) and `:except` (denylist) regex patterns.

**`Formatter`** (`lib/localio/formatter.rb`) — Transforms key names: `:smart`, `:snake_case`, `:camel_case`, `:none`.

### Spreadsheet Format Convention

Spreadsheets must follow a specific structure:
- A `[key]` marker row with language codes as column headers (default language marked with `*`)
- Data rows with key in column A, translations in subsequent columns
- An `[end]` marker row to stop parsing
- Optional `[comment]` rows for documentation (skipped during parsing)

### Adding a New Platform

1. Create `lib/localio/writers/<platform>_writer.rb` with a `write_localizables(holder, path)` class method
2. Create corresponding ERB template(s) in `lib/localio/templates/`
3. Add a case branch in `LocalizableWriter`
4. Add a case branch in the `platform` DSL accessor in `Locfile`
5. Add specs in `spec/writers/`

### Adding a New Source Format

1. Create `lib/localio/processors/<format>_processor.rb` with a `load_localizables(config)` class method returning `{language => [Segment]}`
2. Add a case branch in `Processor`
3. Add specs in `spec/processors/`

## Notes

- `String` is monkey-patched in `lib/localio/string_helper.rb` with color helpers and case-conversion methods used throughout
- The `ConfigStore` (`lib/localio/config_store.rb`) persists OAuth tokens/config to a local YAML file (`.localio.yml`)
- Tests use fixture spreadsheet files in `spec/` directories alongside spec files
