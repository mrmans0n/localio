# Twine Writer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `:twine` platform writer that generates a single Twine-compatible `strings.txt` containing all languages.

**Architecture:** Pure Ruby writer (no ERB template). Single-pass over terms: buffers `[comment]` rows and attaches them to the next real key, maps `[init-node]`/`[end-node]` to Twine `[[section]]` headers, writes all language translations per key. Registered in `localizable_writer.rb` alongside the existing 7 writers.

**Tech Stack:** Ruby 3.2+, RSpec 3.x, stdlib FileUtils

---

## Task 1: Write the TwineWriter spec (failing)

**Files:**
- Create: `spec/localio/writers/twine_writer_spec.rb`

**Step 1: Create the spec file**

```ruby
require 'localio/string_helper'
require 'localio/term'
require 'localio/formatter'
require 'localio/writers/twine_writer'

RSpec.describe TwineWriter do
  include_context 'standard terms'
  # standard terms provides: languages {'en'=>1,'es'=>2,'fr'=>3},
  # default_language 'en', and terms:
  #   [comment] "Section General", app_name, greeting, dots_test, ampersand_test

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates strings.txt in the output path' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'strings.txt'))
      end
    end

    it 'uses a custom filename when :output_file is specified' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          TwineWriter.write(languages, terms, tmpdir, :smart, options.merge(output_file: 'translations.txt'))
        end
        expect(File).to exist(File.join(tmpdir, 'translations.txt'))
        expect(File).not_to exist(File.join(tmpdir, 'strings.txt'))
      end
    end

    it 'includes all languages for each key' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings.txt'))
        expect(content).to include('en = My App')
        expect(content).to include('es = Mi Aplicación')
        expect(content).to include('fr = Mon Application')
      end
    end

    it 'writes [init-node] terms as [[section]] headers' do
      section_terms = [
        Term.new('[init-node]').tap { |t| t.values['en'] = 'General'; t.values['es'] = 'General'; t.values['fr'] = 'General' },
        Term.new('app_name').tap   { |t| t.values['en'] = 'My App';   t.values['es'] = 'Mi App';  t.values['fr'] = 'Mon App' },
        Term.new('[end-node]').tap { |t| t.values['en'] = 'end';      t.values['es'] = 'end';     t.values['fr'] = 'end' },
      ]
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, section_terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings.txt'))
        expect(content).to include('[[General]]')
      end
    end

    it 'attaches [comment] value as comment = on the following key' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { TwineWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings.txt'))
        # [comment] "Section General" appears before app_name and attaches to it
        expect(content).to include("\t\tcomment = Section General")
        # The comment block appears before the greeting key block
        comment_pos  = content.index('comment = Section General')
        greeting_pos = content.index('[greeting]')
        expect(comment_pos).to be < greeting_pos
      end
    end
  end
end
```

**Step 2: Run the spec to confirm it fails with "uninitialized constant TwineWriter"**

```bash
bundle exec rspec spec/localio/writers/twine_writer_spec.rb --format documentation 2>&1
```

Expected: `LoadError` or `NameError: uninitialized constant TwineWriter`

---

## Task 2: Implement TwineWriter

**Files:**
- Create: `lib/localio/writers/twine_writer.rb`

**Step 1: Create the writer**

```ruby
require 'fileutils'
require 'localio/formatter'

class TwineWriter
  def self.write(languages, terms, path, formatter, options)
    puts 'Writing Twine translations...'

    default_language = options[:default_language]
    output_filename  = options[:output_file] || 'strings.txt'

    FileUtils.mkdir_p(path)

    File.open(File.join(path, output_filename), 'w') do |f|
      pending_comment = nil

      terms.each do |term|
        if term.is_comment?
          pending_comment = term.values[default_language]
        elsif term.keyword == '[init-node]'
          f.puts "[[#{term.values[default_language]}]]"
          pending_comment = nil
        elsif term.keyword == '[end-node]'
          f.puts ''
          pending_comment = nil
        else
          key = Formatter.format(term.keyword, formatter, method(:twine_key_formatter))
          f.puts "\t[#{key}]"
          languages.keys.each do |lang|
            f.puts "\t\t#{lang} = #{term.values[lang]}"
          end
          if pending_comment
            f.puts "\t\tcomment = #{pending_comment}"
            pending_comment = nil
          end
          f.puts ''
        end
      end
    end

    puts " > #{output_filename.yellow}"
  end

  private

  def self.twine_key_formatter(key)
    key.space_to_underscore.strip_tag.downcase
  end
end
```

**Step 2: Run the spec to confirm all 5 tests pass**

```bash
bundle exec rspec spec/localio/writers/twine_writer_spec.rb --format documentation 2>&1
```

Expected: `5 examples, 0 failures`

**Step 3: Run the full suite to confirm no regressions**

```bash
bundle exec rspec --format progress 2>&1 | tail -5
```

Expected: `112 examples, 0 failures`

**Step 4: Commit**

```bash
git add lib/localio/writers/twine_writer.rb spec/localio/writers/twine_writer_spec.rb
git commit -m "feat: add TwineWriter for Twine-compatible strings.txt output"
```

---

## Task 3: Register :twine in LocalizableWriter

**Files:**
- Modify: `lib/localio/localizable_writer.rb`

**Step 1: Add the require and case branch**

At the top of `lib/localio/localizable_writer.rb`, add after the last `require` line:

```ruby
require 'localio/writers/twine_writer'
```

In the `case platform` block, add before the `else`:

```ruby
      when :twine
        TwineWriter.write languages, terms, path, formatter, options
```

Also update the error message in the `else` branch to include `:twine`:

```ruby
        raise ArgumentError, 'Platform not supported! Current possibilities are :android, :ios, :json, :rails, :java_properties, :resx, :twine'
```

**Step 2: Run the full suite to confirm nothing broke**

```bash
bundle exec rspec --format progress 2>&1 | tail -5
```

Expected: `112 examples, 0 failures`

**Step 3: Commit**

```bash
git add lib/localio/localizable_writer.rb
git commit -m "feat: register :twine platform in LocalizableWriter"
```

---

## Task 4: Update README

**Files:**
- Modify: `README.md`

**Step 1: Add :twine to the supported platforms list**

Find the `#### Supported platforms` section and add after the `:resx` bullet:

```markdown
* `:twine` for [Twine](https://github.com/scelis/twine)-compatible `strings.txt` files containing all languages in a single file. The `output_path` is the directory where the file will be written.
```

**Step 2: Add a Twine source section after the ResX platform parameters section**

Find the `#### Supported sources` section header and add a new platform parameters sub-section before it (after the ResX section):

```markdown
##### Twine - :twine

By default the output file is named `strings.txt`. Use `:output_file` to override:

````ruby
platform :twine, :output_file => 'MyApp.strings'
````
```

**Step 3: Run the full suite one final time**

```bash
bundle exec rspec --format progress 2>&1 | tail -5
```

Expected: `112 examples, 0 failures`

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: document :twine platform in README"
```
