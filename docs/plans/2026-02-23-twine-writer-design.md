# Twine Writer Design

**Date:** 2026-02-23
**Status:** Approved

## Goal

Add a `:twine` platform writer that generates a [Twine](https://github.com/scelis/twine)-compatible `strings.txt` file containing all languages in a single file.

## Output Format

Standard Twine format with tab indentation. All languages are written per key, not per file.

```
[[section_name]]
	[key_name]
		en = English value
		es = Spanish value
		comment = Optional comment

	[another_key]
		en = Another value
		es = Otro valor
```

## Term Mapping

| Localio term | Twine output |
|---|---|
| `[init-node]` | `[[section_name]]` (value from default language) |
| `[end-node]` | blank line (sections close implicitly) |
| `[comment]` | buffered; written as `comment = ...` under the next real key |
| regular key | `[key]` block with one `lang = value` line per language |

## Architecture

**Approach:** Pure Ruby writer (no ERB template). The comment-buffering logic and single-file-all-languages structure don't fit ERB well.

### Writer class

- **File:** `lib/localio/writers/twine_writer.rb`
- **Class:** `TwineWriter`
- **Interface:** `self.write(languages, terms, path, formatter, options)` — matches all existing writers

### Algorithm (single pass)

1. Open output file (`strings.txt` or `options[:output_file]`)
2. `pending_comment = nil`
3. For each term:
   - `[comment]` → store `pending_comment` from default language value
   - `[init-node]` → write `[[value]]`, reset `pending_comment`
   - `[end-node]` → write blank line
   - regular key → write `[key]` block with all lang translations; if `pending_comment` is set, append `\t\tcomment = ...` and clear it

### Platform registration

- Registered in `lib/localio.rb` as `:twine`
- Locfile usage: `platform :twine` or `platform :twine, :output_file => 'custom.txt'`

### Key formatting

- Smart formatter defaults to snake_case (consistent with android/rails)

## Testing

`spec/localio/writers/twine_writer_spec.rb` using the existing `standard terms` shared context and `Dir.mktmpdir` isolation. Cases:

- Creates `strings.txt` in the output path
- All languages present in each key block
- `[init-node]` produces `[[section]]` header
- `[comment]` row attaches as `comment = ...` to the following key
- `:output_file` option overrides the default filename
