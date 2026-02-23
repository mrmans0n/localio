# Localio Modernization Design

**Date:** 2026-02-23
**Approach:** Option A — tests first, then dependency updates

## Overview

Modernize the Localio gem in two phases:

1. Write a comprehensive RSpec test suite with fixtures and mocks
2. Update all dependencies to current versions and target Ruby 3.x, using the test suite as a safety net

## Phase 1: Test Suite

### Structure

```
spec/
  spec_helper.rb
  fixtures/
    sample.csv          # canonical test data: keys in 3 languages, special chars, comments, multi-level keys
    sample.xlsx         # small binary fixture
    sample.xls          # small binary fixture
  localio/
    term_spec.rb
    segment_spec.rb
    filter_spec.rb
    formatter_spec.rb
    template_handler_spec.rb
    processors/
      csv_processor_spec.rb
      xlsx_processor_spec.rb
      xls_processor_spec.rb
      google_drive_processor_spec.rb   # mocked worksheet interface
    writers/
      android_writer_spec.rb
      ios_writer_spec.rb
      swift_writer_spec.rb
      json_writer_spec.rb
      rails_writer_spec.rb
      java_properties_writer_spec.rb
      resx_writer_spec.rb
  localio_spec.rb       # end-to-end: CSV fixture → writer → verify output files
```

### Fixture Data

A single canonical `sample.csv` covers all test scenarios:
- Normal keys with translations in 3 languages
- Special characters: ampersands, ellipsis, printf format strings
- Comment rows
- Multi-level/nested keys (dot-separated) for JSON nesting tests

The same fixture data drives all processor and writer tests for consistency.

### Testing Strategy Per Layer

**Models (Term, Segment):** Construction, attribute access, `is_comment?` detection.

**Filter:** `only` and `except` with regex patterns against a fixed segment list.

**Formatter:** All 4 modes (`:smart`, `:none`, `:camel_case`, `:snake_case`) against varied key strings.

**Processors:**
- CSV/XLSX/XLS: Parse real fixture files, assert correct Term extraction, language detection, comment handling
- Google Drive: Mock the gem's worksheet interface, test the same parsing logic in isolation

**TemplateHandler:** Render ERB templates, write to `Dir.mktmpdir`, assert output matches expected content.

**Writers (all 7):** Feed a fixed Terms array → call writer → assert output files in a temp dir contain expected strings (spot-check key lines, not byte-perfect comparison).

**Pipeline (`localio_spec.rb`):** CSV fixture → Android + JSON writers → verify files exist with correct content.

### Key Test Helpers
- Shared `let(:terms)` factory via RSpec shared contexts
- `Dir.mktmpdir` for output isolation in all writer and template tests
- No network calls; Google Drive mocked at the worksheet interface level

## Phase 2: Dependency Updates

| Gem | Current | Target | Notes |
|-----|---------|--------|-------|
| `google_drive` | `~> 1.0` | `~> 3.0` | API changed; processor needs update |
| `spreadsheet` | `~> 1.0` | `~> 1.3` | Minor updates only |
| `simple_xlsx_reader` | `~> 1.0` | `~> 2.0` | Breaking changes in v2 |
| `nokogiri` | `~> 1.6` | `~> 1.16` | Mostly drop-in |
| `micro-optparse` | `~> 1.2` | remove → stdlib `optparse` | Unmaintained |
| `bundler` | `~> 1.3` | `~> 2.0` | Dev dep |
| Ruby | `>= 1.9.2` | `>= 3.0` | Gemspec update |

The green test suite from Phase 1 is the safety net — failures after dep updates pinpoint exactly what broke.
