# Localio Modernization: Test Suite + Dependency Updates

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add comprehensive RSpec test coverage to the Localio gem, then update all dependencies to support Ruby 3.x.

**Architecture:** Phase 1 writes tests against the existing codebase using fixtures and mocks. Phase 2 updates dependencies using the test suite as a safety net. All writer tests use `Dir.mktmpdir` + `Dir.chdir` for file isolation. External services (Google Drive, XLSX/XLS readers) are mocked at the library interface level.

**Tech Stack:** Ruby 3.x, RSpec 3.x, built-in CSV, mocked google_drive/spreadsheet/simple_xlsx_reader

---

## Phase 1: Test Suite

### Task 1: Bootstrap RSpec

**Files:**
- Create: `spec/spec_helper.rb`
- Create: `.rspec`

**Step 1: Create `.rspec`**

```
--require spec_helper
--format documentation
--color
```

**Step 2: Create `spec/spec_helper.rb`**

```ruby
require 'tmpdir'
require 'fileutils'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.order = :random
end
```

**Step 3: Run RSpec**

Run: `bundle exec rspec`
Expected: `0 examples, 0 failures`

**Step 4: Commit**

```bash
git add spec/spec_helper.rb .rspec
git commit -m "test: bootstrap RSpec with spec_helper"
```

---

### Task 2: Create fixture CSV and shared terms

**Files:**
- Create: `spec/fixtures/sample.csv`
- Create: `spec/support/shared_terms.rb`

**Step 1: Create `spec/fixtures/sample.csv`**

```
Title Row,,,
[key],*en,es,fr
[comment],Section General,Section General,Section General
app_name,My App,Mi Aplicación,Mon Application
greeting,Hello %@ world,Hola %@ mundo,Bonjour %@ monde
dots_test,Wait...,Espera...,Attendez...
ampersand_test,Tom & Jerry,Tom & Jerry,Tom & Jerry
[init-node],module,module,module
nested_key,Module Key,Clave Módulo,Clé Module
[end-node],end,end,end
[end],,,
```

This gives 8 terms between `[key]` and `[end]`. Languages: en (default, marked with `*`), es, fr.
All cells have values to avoid nil-translation bugs in writers.

**Step 2: Create `spec/support/shared_terms.rb`**

```ruby
require 'localio/term'

RSpec.shared_context 'standard terms' do
  let(:languages) { { 'en' => 1, 'es' => 2, 'fr' => 3 } }
  let(:default_language) { 'en' }
  let(:terms) do
    [
      Term.new('[comment]').tap do |t|
        t.values['en'] = 'Section General'
        t.values['es'] = 'Section General'
        t.values['fr'] = 'Section General'
      end,
      Term.new('app_name').tap do |t|
        t.values['en'] = 'My App'
        t.values['es'] = 'Mi Aplicación'
        t.values['fr'] = 'Mon Application'
      end,
      Term.new('greeting').tap do |t|
        t.values['en'] = 'Hello %@ world'
        t.values['es'] = 'Hola %@ mundo'
        t.values['fr'] = 'Bonjour %@ monde'
      end,
      Term.new('dots_test').tap do |t|
        t.values['en'] = 'Wait...'
        t.values['es'] = 'Espera...'
        t.values['fr'] = 'Attendez...'
      end,
      Term.new('ampersand_test').tap do |t|
        t.values['en'] = 'Tom & Jerry'
        t.values['es'] = 'Tom & Jerry'
        t.values['fr'] = 'Tom & Jerry'
      end,
    ]
  end
end
```

**Step 3: Commit**

```bash
git add spec/fixtures/sample.csv spec/support/shared_terms.rb
git commit -m "test: add sample CSV fixture and shared terms context"
```

---

### Task 3: StringHelper tests

**Files:**
- Create: `spec/localio/string_helper_spec.rb`

**Step 1: Write test**

```ruby
require 'localio/string_helper'

RSpec.describe String do
  describe '#space_to_underscore' do
    it { expect('hello world'.space_to_underscore).to eq('hello_world') }
    it { expect('hello'.space_to_underscore).to eq('hello') }
  end

  describe '#strip_tag' do
    it 'strips single-letter bracket tags from the start' do
      expect('[a]hello'.strip_tag).to eq('hello')
    end
    it 'does not strip multi-letter bracket tags' do
      expect('[comment]hello'.strip_tag).to eq('[comment]hello')
    end
    it 'does not strip tags not at the start' do
      expect('hello[a]'.strip_tag).to eq('hello[a]')
    end
  end

  describe '#camel_case' do
    it { expect('hello_world'.camel_case).to eq('HelloWorld') }
    it { expect('HelloWorld'.camel_case).to eq('HelloWorld') }
  end

  describe '#replace_escaped' do
    it { expect('a`+b'.replace_escaped).to eq('a+b') }
    it { expect('a`=b'.replace_escaped).to eq('a=b') }
    it { expect("a\\+b".replace_escaped).to eq('a+b') }
  end

  describe '#underscore' do
    it { expect('HelloWorld'.underscore).to eq('hello_world') }
  end

  describe '#uncapitalize' do
    it { expect('Hello'.uncapitalize).to eq('hello') }
  end

  describe '#blank?' do
    it { expect(''.blank?).to be true }
    it { expect('hello'.blank?).to be false }
  end

  describe '#green / #yellow / #red / #cyan' do
    it { expect('ok'.green).to include("\e[32m") }
    it { expect('ok'.yellow).to include("\e[33m") }
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/localio/string_helper_spec.rb`
Expected: all pass

**Step 3: Commit**

```bash
git add spec/localio/string_helper_spec.rb
git commit -m "test: StringHelper string extension tests"
```

---

### Task 4: Term and Segment model tests

**Files:**
- Create: `spec/localio/term_spec.rb`
- Create: `spec/localio/segment_spec.rb`

**Step 1: Write `spec/localio/term_spec.rb`**

```ruby
require 'localio/term'

RSpec.describe Term do
  subject(:term) { Term.new('app_name') }

  it 'stores the keyword' do
    expect(term.keyword).to eq('app_name')
  end

  it 'initializes with empty values hash' do
    expect(term.values).to be_empty
  end

  it 'stores values by language' do
    term.values['en'] = 'My App'
    expect(term.values['en']).to eq('My App')
  end

  describe '#is_comment?' do
    it { expect(Term.new('[comment]').is_comment?).to be true }
    it { expect(Term.new('[COMMENT]').is_comment?).to be true }
    it { expect(term.is_comment?).to be false }
  end
end
```

**Step 2: Write `spec/localio/segment_spec.rb`**

```ruby
require 'localio/string_helper'
require 'localio/segment'

RSpec.describe Segment do
  subject(:segment) { Segment.new('app_name', 'My App', 'en') }

  it 'stores key, translation, and language' do
    expect(segment.key).to eq('app_name')
    expect(segment.translation).to eq('My App')
    expect(segment.language).to eq('en')
  end

  it 'processes translation through replace_escaped' do
    seg = Segment.new('key', 'hello`+world', 'en')
    expect(seg.translation).to eq('hello+world')
  end

  describe '#is_comment?' do
    it 'returns true when key is nil' do
      segment.key = nil
      expect(segment.is_comment?).to be true
    end
    it 'returns false when key is set' do
      expect(segment.is_comment?).to be false
    end
  end
end
```

**Step 3: Run tests**

Run: `bundle exec rspec spec/localio/term_spec.rb spec/localio/segment_spec.rb`
Expected: all pass

**Step 4: Commit**

```bash
git add spec/localio/term_spec.rb spec/localio/segment_spec.rb
git commit -m "test: Term and Segment model tests"
```

---

### Task 5: SegmentsListHolder, Filter, and Formatter tests

**Files:**
- Create: `spec/localio/segments_list_holder_spec.rb`
- Create: `spec/localio/filter_spec.rb`
- Create: `spec/localio/formatter_spec.rb`

**Step 1: Write `spec/localio/segments_list_holder_spec.rb`**

```ruby
require 'localio/segments_list_holder'

RSpec.describe SegmentsListHolder do
  subject(:holder) { SegmentsListHolder.new('en') }

  it { expect(holder.language).to eq('en') }
  it { expect(holder.segments).to be_empty }

  describe '#get_binding' do
    it 'returns a Binding' do
      expect(holder.get_binding).to be_a(Binding)
    end

    it 'exposes @language in the binding' do
      expect(eval('@language', holder.get_binding)).to eq('en')
    end

    it 'exposes @segments in the binding' do
      expect(eval('@segments', holder.get_binding)).to eq([])
    end
  end
end
```

**Step 2: Write `spec/localio/filter_spec.rb`**

Note: `Filter` operates on `Term` objects (not `Segment`), matching against `term.keyword`.

```ruby
require 'localio/term'
require 'localio/filter'

RSpec.describe Filter do
  let(:terms) do
    ['app_name', 'app_title', 'settings_title', 'settings_back', '[comment]'].map { |kw| Term.new(kw) }
  end

  describe '.apply_filter' do
    it 'returns all terms when no filters set' do
      expect(Filter.apply_filter(terms, nil, nil)).to eq(terms)
    end

    context 'with only filter' do
      it 'keeps terms matching the regex' do
        result = Filter.apply_filter(terms, { keys: 'app_' }, nil)
        expect(result.map(&:keyword)).to contain_exactly('app_name', 'app_title')
      end

      it 'returns empty array when nothing matches' do
        expect(Filter.apply_filter(terms, { keys: 'nonexistent' }, nil)).to be_empty
      end
    end

    context 'with except filter' do
      it 'excludes terms matching the regex' do
        result = Filter.apply_filter(terms, nil, { keys: 'settings_' })
        expect(result.map(&:keyword)).not_to include('settings_title', 'settings_back')
        expect(result.map(&:keyword)).to include('app_name', 'app_title')
      end
    end

    context 'with both filters' do
      it 'applies only first then except' do
        result = Filter.apply_filter(terms, { keys: 'app_' }, { keys: 'title' })
        expect(result.map(&:keyword)).to contain_exactly('app_name')
      end
    end
  end
end
```

**Step 3: Write `spec/localio/formatter_spec.rb`**

```ruby
require 'localio/string_helper'
require 'localio/formatter'

RSpec.describe Formatter do
  let(:smart_callback) { ->(key) { key.upcase } }

  describe '.format' do
    it ':smart delegates to callback' do
      expect(Formatter.format('hello', :smart, smart_callback)).to eq('HELLO')
    end

    it ':none returns key unchanged' do
      expect(Formatter.format('Hello World', :none, smart_callback)).to eq('Hello World')
    end

    it ':camel_case converts to CamelCase' do
      expect(Formatter.format('hello world', :camel_case, smart_callback)).to eq('HelloWorld')
    end

    it ':camel_case strips single-letter bracket tags' do
      expect(Formatter.format('[a]hello', :camel_case, smart_callback)).to eq('Hello')
    end

    it ':snake_case converts spaces to underscores and downcases' do
      expect(Formatter.format('Hello World', :snake_case, smart_callback)).to eq('hello_world')
    end

    it 'raises ArgumentError for unknown formatter' do
      expect { Formatter.format('key', :unknown, smart_callback) }.to raise_error(ArgumentError)
    end
  end
end
```

**Step 4: Run tests**

Run: `bundle exec rspec spec/localio/segments_list_holder_spec.rb spec/localio/filter_spec.rb spec/localio/formatter_spec.rb`
Expected: all pass

**Step 5: Commit**

```bash
git add spec/localio/segments_list_holder_spec.rb spec/localio/filter_spec.rb spec/localio/formatter_spec.rb
git commit -m "test: SegmentsListHolder, Filter, and Formatter tests"
```

---

### Task 6: TemplateHandler tests

**Files:**
- Create: `spec/localio/template_handler_spec.rb`

The `TemplateHandler` writes an intermediate file in cwd before copying to the target directory.
Use `Dir.chdir(tmpdir) { }` (block form, restores cwd on exit) to keep intermediate files in tmpdir.

**Step 1: Write test**

```ruby
require 'localio/string_helper'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/template_handler'

RSpec.describe TemplateHandler do
  let(:holder) do
    h = SegmentsListHolder.new('en')
    h.segments << Segment.new('app_name', 'My App', 'en')
    h.segments << Segment.new('greeting', 'Hello world', 'en')
    h
  end

  describe '.process_template' do
    it 'creates the output file in the target directory' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          TemplateHandler.process_template('rails_localizable.erb', tmpdir, 'en.yml', holder)
          expect(File).to exist(File.join(tmpdir, 'en.yml'))
        end
      end
    end

    it 'renders ERB template content correctly' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          TemplateHandler.process_template('rails_localizable.erb', tmpdir, 'en.yml', holder)
          content = File.read(File.join(tmpdir, 'en.yml'))
          expect(content).to include('en:')
          expect(content).to include('app_name: "My App"')
          expect(content).to include('greeting: "Hello world"')
        end
      end
    end

    it 'does not leave a stray temp file in the working directory' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          TemplateHandler.process_template('rails_localizable.erb', tmpdir, 'en.yml', holder)
          files = Dir.entries(tmpdir).reject { |f| f.start_with?('.') }
          expect(files).to eq(['en.yml'])
        end
      end
    end

    it 'creates subdirectories as needed' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          subdir = File.join(tmpdir, 'values')
          TemplateHandler.process_template('rails_localizable.erb', subdir, 'en.yml', holder)
          expect(File).to exist(File.join(subdir, 'en.yml'))
        end
      end
    end
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/localio/template_handler_spec.rb`
Expected: all pass

**Step 3: Commit**

```bash
git add spec/localio/template_handler_spec.rb
git commit -m "test: TemplateHandler tests"
```

---

### Task 7: CsvProcessor tests

**Files:**
- Create: `spec/localio/processors/csv_processor_spec.rb`

**Step 1: Write test**

```ruby
require 'localio/term'
require 'localio/string_helper'
require 'localio/processors/csv_processor'

RSpec.describe CsvProcessor do
  let(:fixture_path) { File.expand_path('../../../fixtures/sample.csv', __FILE__) }
  let(:platform_options) { {} }
  let(:options) { { path: fixture_path } }

  describe '.load_localizables' do
    subject(:result) { CsvProcessor.load_localizables(platform_options, options) }

    it 'returns languages en, es, fr' do
      expect(result[:languages].keys).to contain_exactly('en', 'es', 'fr')
    end

    it 'sets en as default language (marked with *)' do
      expect(result[:default_language]).to eq('en')
    end

    it 'returns 8 terms between [key] and [end]' do
      expect(result[:segments].count).to eq(8)
    end

    it 'parses term keywords correctly' do
      keywords = result[:segments].map(&:keyword)
      expect(keywords).to include('app_name', 'greeting', '[comment]', '[init-node]', '[end-node]')
    end

    it 'parses translations for each language' do
      app_name = result[:segments].find { |t| t.keyword == 'app_name' }
      expect(app_name.values['en']).to eq('My App')
      expect(app_name.values['es']).to eq('Mi Aplicación')
      expect(app_name.values['fr']).to eq('Mon Application')
    end

    it 'identifies comment rows' do
      comment = result[:segments].find { |t| t.keyword == '[comment]' }
      expect(comment.is_comment?).to be true
    end

    it 'raises ArgumentError when :path is missing' do
      expect { CsvProcessor.load_localizables({}, {}) }
        .to raise_error(ArgumentError, /:path attribute is missing/)
    end

    it 'raises IndexError when [key] marker is missing' do
      Dir.mktmpdir do |tmpdir|
        path = File.join(tmpdir, 'bad.csv')
        File.write(path, "no,key,row\ndata,here,\n[end],,,\n")
        expect { CsvProcessor.load_localizables({}, { path: path }) }
          .to raise_error(IndexError, /Could not find any \[key\]/)
      end
    end

    it 'raises IndexError when [end] marker is missing' do
      Dir.mktmpdir do |tmpdir|
        path = File.join(tmpdir, 'bad.csv')
        File.write(path, "title,,,\n[key],*en,es,\ndata,val,val,\n")
        expect { CsvProcessor.load_localizables({}, { path: path }) }
          .to raise_error(IndexError, /Could not find any \[end\]/)
      end
    end

    context 'with override_default option' do
      let(:platform_options) { { override_default: 'es' } }

      it 'uses the overridden default language' do
        expect(result[:default_language]).to eq('es')
      end
    end

    context 'with avoid_lang_downcase option' do
      let(:tmpdir) { Dir.mktmpdir }
      let(:options) do
        path = File.join(tmpdir, 'upper.csv')
        File.write(path, "Title,,,\n[key],*EN,ES,FR\napp_name,My App,Mi App,Mon App\n[end],,,\n")
        { path: path }
      end
      let(:platform_options) { { avoid_lang_downcase: true } }

      after { FileUtils.rm_rf(tmpdir) }

      it 'preserves language case' do
        expect(result[:languages].keys).to contain_exactly('EN', 'ES', 'FR')
      end
    end
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/localio/processors/csv_processor_spec.rb`
Expected: all pass (CSV is stdlib, no external gem)

**Step 3: Commit**

```bash
git add spec/localio/processors/csv_processor_spec.rb
git commit -m "test: CsvProcessor tests"
```

---

### Task 8: XlsxProcessor tests (mocked)

**Files:**
- Create: `spec/localio/processors/xlsx_processor_spec.rb`

Mock `SimpleXlsxReader` to avoid needing a binary fixture file.

**Step 1: Write test**

```ruby
require 'localio/term'
require 'localio/string_helper'
require 'localio/processors/xlsx_processor'

RSpec.describe XlsxProcessor do
  let(:rows) do
    [
      ['Title', nil, nil, nil],
      ['[key]', '*en', 'es', 'fr'],
      ['[comment]', 'Section General', 'Section General', 'Section General'],
      ['app_name', 'My App', 'Mi Aplicación', 'Mon Application'],
      ['greeting', 'Hello', 'Hola', 'Bonjour'],
      ['[end]', nil, nil, nil],
    ]
  end

  let(:sheet_double) { double('sheet', rows: rows) }
  let(:book_double) { double('book', sheets: [sheet_double]) }

  before { allow(SimpleXlsxReader).to receive(:open).and_return(book_double) }

  let(:options) { { path: 'fake.xlsx', sheet: 0 } }
  let(:platform_options) { {} }

  describe '.load_localizables' do
    subject(:result) { XlsxProcessor.load_localizables(platform_options, options) }

    it 'raises ArgumentError when :path is missing' do
      expect { XlsxProcessor.load_localizables({}, {}) }
        .to raise_error(ArgumentError, /:path attribute is missing/)
    end

    it 'returns languages en, es, fr' do
      expect(result[:languages].keys).to contain_exactly('en', 'es', 'fr')
    end

    it 'sets en as default language' do
      expect(result[:default_language]).to eq('en')
    end

    it 'returns 3 terms' do
      expect(result[:segments].count).to eq(3)
    end

    it 'parses translations correctly' do
      app_name = result[:segments].find { |t| t.keyword == 'app_name' }
      expect(app_name.values['en']).to eq('My App')
      expect(app_name.values['es']).to eq('Mi Aplicación')
    end

    it 'selects sheet by string name' do
      named_sheet = double('sheet', name: 'Translations', rows: rows)
      allow(book_double).to receive(:sheets).and_return([named_sheet])
      allow(book_double.sheets).to receive(:detect).and_call_original
      result = XlsxProcessor.load_localizables({}, { path: 'fake.xlsx', sheet: 'Translations' })
      expect(result[:languages].keys).to include('en')
    end

    it 'raises when sheet is nil' do
      allow(book_double).to receive(:sheets).and_return([double('sheet', rows: rows)])
      allow(book_double.sheets).to receive(:detect).and_return(nil)
      expect { XlsxProcessor.load_localizables({}, { path: 'fake.xlsx', sheet: 'Missing' }) }
        .to raise_error(RuntimeError, /Unable to retrieve/)
    end
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/localio/processors/xlsx_processor_spec.rb`
Expected: pass if `simple_xlsx_reader` installs under current Ruby; note failures for Phase 2 if not

**Step 3: Commit**

```bash
git add spec/localio/processors/xlsx_processor_spec.rb
git commit -m "test: XlsxProcessor tests (mocked)"
```

---

### Task 9: XlsProcessor tests (mocked)

**Files:**
- Create: `spec/localio/processors/xls_processor_spec.rb`

Mock the `Spreadsheet` gem worksheet interface. XLS uses `worksheet[row, col]` (0-indexed rows).

**Step 1: Write test**

```ruby
require 'localio/term'
require 'localio/string_helper'
require 'localio/processors/xls_processor'

RSpec.describe XlsProcessor do
  let(:data) do
    {
      [0, 0] => '[key]',    [0, 1] => '*en',  [0, 2] => 'es',           [0, 3] => 'fr',
      [1, 0] => 'app_name', [1, 1] => 'My App', [1, 2] => 'Mi Aplicación', [1, 3] => 'Mon Application',
      [2, 0] => 'greeting', [2, 1] => 'Hello',  [2, 2] => 'Hola',          [2, 3] => 'Bonjour',
      [3, 0] => '[end]',    [3, 1] => '',       [3, 2] => '',              [3, 3] => '',
    }
  end

  let(:worksheet) do
    ws = double('worksheet')
    allow(ws).to receive(:[]) { |row, col| data[[row, col]].to_s }
    allow(ws).to receive(:row_count).and_return(3)
    allow(ws).to receive(:column_count).and_return(3)
    ws
  end

  let(:book_double) { double('book') }

  before do
    allow(Spreadsheet).to receive(:client_encoding=)
    allow(Spreadsheet).to receive(:open).and_return(book_double)
    allow(book_double).to receive(:worksheet).with(0).and_return(worksheet)
  end

  let(:options) { { path: 'fake.xls' } }
  let(:platform_options) { {} }

  describe '.load_localizables' do
    subject(:result) { XlsProcessor.load_localizables(platform_options, options) }

    it 'raises ArgumentError when :path is missing' do
      expect { XlsProcessor.load_localizables({}, {}) }
        .to raise_error(ArgumentError, /:path attribute is missing/)
    end

    it 'returns languages en, es, fr' do
      expect(result[:languages].keys).to contain_exactly('en', 'es', 'fr')
    end

    it 'sets en as default language' do
      expect(result[:default_language]).to eq('en')
    end

    it 'returns 2 terms' do
      expect(result[:segments].count).to eq(2)
    end

    it 'parses translations correctly' do
      app_name = result[:segments].find { |t| t.keyword == 'app_name' }
      expect(app_name.values['en']).to eq('My App')
    end

    it 'raises when worksheet is nil' do
      allow(book_double).to receive(:worksheet).and_return(nil)
      expect { XlsProcessor.load_localizables({}, { path: 'fake.xls' }) }
        .to raise_error(RuntimeError, /Unable to retrieve/)
    end
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/localio/processors/xls_processor_spec.rb`
Expected: pass if `spreadsheet` gem installs; note failures for Phase 2 if not

**Step 3: Commit**

```bash
git add spec/localio/processors/xls_processor_spec.rb
git commit -m "test: XlsProcessor tests (mocked)"
```

---

### Task 10: GoogleDriveProcessor tests (mocked)

**Files:**
- Create: `spec/localio/processors/google_drive_processor_spec.rb`

Mock the entire GoogleDrive session and auth. Focus on argument validation and parsing logic.

**Step 1: Write test**

```ruby
require 'localio/term'
require 'localio/string_helper'
require 'localio/processors/google_drive_processor'

RSpec.describe GoogleDriveProcessor do
  let(:ws_data) do
    {
      [1, 1] => '[key]',    [1, 2] => '*en',  [1, 3] => 'es',
      [2, 1] => 'app_name', [2, 2] => 'My App', [2, 3] => 'Mi Aplicación',
      [3, 1] => 'greeting', [3, 2] => 'Hello',  [3, 3] => 'Hola',
      [4, 1] => '[end]',    [4, 2] => '',        [4, 3] => '',
    }
  end

  let(:worksheet) do
    ws = double('worksheet')
    allow(ws).to receive(:[]) { |row, col| ws_data[[row, col]].to_s }
    allow(ws).to receive(:max_rows).and_return(4)
    allow(ws).to receive(:max_cols).and_return(3)
    ws
  end

  let(:spreadsheet_double) { double('spreadsheet', title: 'My Translations') }
  let(:session_double) { double('session') }

  before do
    allow(spreadsheet_double).to receive(:worksheets).and_return([worksheet])
    allow(session_double).to receive(:spreadsheets).and_return([spreadsheet_double])
    allow(GoogleDrive).to receive(:login_with_oauth).and_return(session_double)

    auth = double('auth',
      authorization_uri: 'http://example.com',
      access_token: 'token',
      refresh_token: 'refresh'
    )
    allow(auth).to receive(:client_id=)
    allow(auth).to receive(:client_secret=)
    allow(auth).to receive(:scope=)
    allow(auth).to receive(:redirect_uri=)
    allow(auth).to receive(:refresh_token=)
    allow(auth).to receive(:refresh!)

    client = double('client', authorization: auth)
    stub_const('Google::APIClient', double(new: client))
    stub_const('Localio::VERSION', '0.1.7')

    config = double('config', has?: false, get: nil)
    allow(config).to receive(:store)
    allow(config).to receive(:persist)
    allow(ConfigStore).to receive(:new).and_return(config)
  end

  let(:options) do
    { spreadsheet: 'My Translations', client_id: 'id', client_secret: 'secret', client_token: 'token', sheet: 0 }
  end

  describe '.load_localizables' do
    subject(:result) { GoogleDriveProcessor.load_localizables({}, options) }

    it 'raises when :spreadsheet is missing' do
      expect { GoogleDriveProcessor.load_localizables({}, { client_id: 'a', client_secret: 'b' }) }
        .to raise_error(ArgumentError, /:spreadsheet required/)
    end

    it 'raises when :login is provided (deprecated)' do
      expect { GoogleDriveProcessor.load_localizables({}, { spreadsheet: 'x', login: 'u', client_id: 'a', client_secret: 'b' }) }
        .to raise_error(ArgumentError, /:login is deprecated/)
    end

    it 'raises when :client_id is missing' do
      expect { GoogleDriveProcessor.load_localizables({}, { spreadsheet: 'x', client_secret: 'b' }) }
        .to raise_error(ArgumentError, /:client_id required/)
    end

    it 'raises when :client_secret is missing' do
      expect { GoogleDriveProcessor.load_localizables({}, { spreadsheet: 'x', client_id: 'a' }) }
        .to raise_error(ArgumentError, /:client_secret required/)
    end

    it 'returns languages en and es' do
      expect(result[:languages].keys).to contain_exactly('en', 'es')
    end

    it 'sets en as default language' do
      expect(result[:default_language]).to eq('en')
    end

    it 'parses translations' do
      app_name = result[:segments].find { |t| t.keyword == 'app_name' }
      expect(app_name.values['en']).to eq('My App')
    end
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/localio/processors/google_drive_processor_spec.rb`
Expected: may fail if `google_drive ~> 1.0` does not install under Ruby 3.x — note for Phase 2

**Step 3: Commit**

```bash
git add spec/localio/processors/google_drive_processor_spec.rb
git commit -m "test: GoogleDriveProcessor tests (mocked)"
```

---

### Task 11: AndroidWriter tests

**Files:**
- Create: `spec/localio/writers/android_writer_spec.rb`

**Step 1: Write test**

```ruby
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/android_writer'

RSpec.describe AndroidWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates values/strings.xml for the default language' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'values', 'strings.xml'))
      end
    end

    it 'creates values-{lang}/strings.xml for non-default languages' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'values-es', 'strings.xml'))
        expect(File).to exist(File.join(tmpdir, 'values-fr', 'strings.xml'))
      end
    end

    it 'converts & to &amp; in translations' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('&amp; Jerry')
        expect(content).not_to include('"Tom & Jerry"')
      end
    end

    it 'converts ... to … in translations' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('Wait…')
      end
    end

    it 'converts %@ to %s in translations' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('%s world')
      end
    end

    it 'renders comment rows as XML comments' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('<!-- Section General -->')
      end
    end

    it 'includes app_name string resource' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { AndroidWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('<string name="app_name">My App</string>')
      end
    end
  end
end
```

**Step 2: Run test**

Run: `bundle exec rspec spec/localio/writers/android_writer_spec.rb`
Expected: all pass

**Step 3: Commit**

```bash
git add spec/localio/writers/android_writer_spec.rb
git commit -m "test: AndroidWriter tests"
```

---

### Task 12: IosWriter and SwiftWriter tests

**Files:**
- Create: `spec/localio/writers/ios_writer_spec.rb`
- Create: `spec/localio/writers/swift_writer_spec.rb`

**Step 1: Write `spec/localio/writers/ios_writer_spec.rb`**

```ruby
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/ios_writer'

RSpec.describe IosWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates Localizable.strings in {lang}.lproj/ for each language' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
        expect(File).to exist(File.join(tmpdir, 'es.lproj', 'Localizable.strings'))
      end
    end

    it 'creates LocalizableConstants.h by default' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'LocalizableConstants.h'))
      end
    end

    it 'skips LocalizableConstants.h when create_constants is false' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { IosWriter.write(languages, terms, tmpdir, :smart, options.merge(create_constants: false)) }
        expect(File).not_to exist(File.join(tmpdir, 'LocalizableConstants.h'))
      end
    end

    it 'renders comment rows as line comments' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
        expect(content).to include('// Section General')
      end
    end

    it 'includes translation values' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { IosWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
        expect(content).to include('My App')
      end
    end
  end
end
```

**Step 2: Write `spec/localio/writers/swift_writer_spec.rb`**

```ruby
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/swift_writer'

RSpec.describe SwiftWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates Localizable.strings in {lang}.lproj/' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { SwiftWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'en.lproj', 'Localizable.strings'))
      end
    end

    it 'creates LocalizableConstants.swift by default' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { SwiftWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'LocalizableConstants.swift'))
      end
    end

    it 'skips LocalizableConstants.swift when create_constants is false' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { SwiftWriter.write(languages, terms, tmpdir, :smart, options.merge(create_constants: false)) }
        expect(File).not_to exist(File.join(tmpdir, 'LocalizableConstants.swift'))
      end
    end
  end
end
```

**Step 3: Run tests**

Run: `bundle exec rspec spec/localio/writers/ios_writer_spec.rb spec/localio/writers/swift_writer_spec.rb`
Expected: all pass

**Step 4: Commit**

```bash
git add spec/localio/writers/ios_writer_spec.rb spec/localio/writers/swift_writer_spec.rb
git commit -m "test: IosWriter and SwiftWriter tests"
```

---

### Task 13: JsonWriter, RailsWriter, JavaPropertiesWriter, ResXWriter tests

**Files:**
- Create: `spec/localio/writers/json_writer_spec.rb`
- Create: `spec/localio/writers/rails_writer_spec.rb`
- Create: `spec/localio/writers/java_properties_writer_spec.rb`
- Create: `spec/localio/writers/resx_writer_spec.rb`

**Step 1: Write `spec/localio/writers/json_writer_spec.rb`**

```ruby
require 'json'
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/json_writer'

RSpec.describe JsonWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates strings-{lang}.json for each language' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'strings-en.json'))
        expect(File).to exist(File.join(tmpdir, 'strings-es.json'))
        expect(File).to exist(File.join(tmpdir, 'strings-fr.json'))
      end
    end

    it 'produces valid JSON' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'strings-en.json'))
        expect { JSON.parse(content) }.not_to raise_error
      end
    end

    it 'includes translation values' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        data = JSON.parse(File.read(File.join(tmpdir, 'strings-en.json')))
        expect(data['translations']['app_name']).to eq('My App')
      end
    end

    it 'sets correct language in meta' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { JsonWriter.write(languages, terms, tmpdir, :smart, options) }
        data = JSON.parse(File.read(File.join(tmpdir, 'strings-es.json')))
        expect(data['meta']['language']).to eq('es')
      end
    end
  end
end
```

**Step 2: Write `spec/localio/writers/rails_writer_spec.rb`**

```ruby
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/rails_writer'

RSpec.describe RailsWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates {lang}.yml for each language' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { RailsWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'en.yml'))
        expect(File).to exist(File.join(tmpdir, 'es.yml'))
        expect(File).to exist(File.join(tmpdir, 'fr.yml'))
      end
    end

    it 'starts YAML with the language key' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { RailsWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.yml'))
        expect(content).to include('en:')
        expect(content).to include('app_name: "My App"')
      end
    end

    it 'renders comment rows as YAML comments' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { RailsWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'en.yml'))
        expect(content).to include('# Section General')
      end
    end
  end
end
```

**Step 3: Write `spec/localio/writers/java_properties_writer_spec.rb`**

```ruby
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/java_properties_writer'

RSpec.describe JavaPropertiesWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates language_{lang}.properties for each language' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { JavaPropertiesWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'language_en.properties'))
        expect(File).to exist(File.join(tmpdir, 'language_es.properties'))
      end
    end

    it 'includes translation values' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { JavaPropertiesWriter.write(languages, terms, tmpdir, :smart, options) }
        content = File.read(File.join(tmpdir, 'language_en.properties'))
        expect(content).to include('My App')
      end
    end
  end
end
```

**Step 4: Write `spec/localio/writers/resx_writer_spec.rb`**

```ruby
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/writers/resx_writer'

RSpec.describe ResXWriter do
  include_context 'standard terms'

  let(:options) { { default_language: 'en' } }

  describe '.write' do
    it 'creates Resources.resx for the default language' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { ResXWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'Resources.resx'))
      end
    end

    it 'creates Resources.{lang}.resx for non-default languages' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { ResXWriter.write(languages, terms, tmpdir, :smart, options) }
        expect(File).to exist(File.join(tmpdir, 'Resources.es.resx'))
        expect(File).to exist(File.join(tmpdir, 'Resources.fr.resx'))
      end
    end

    it 'uses custom resource_file name when specified' do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { ResXWriter.write(languages, terms, tmpdir, :smart, options.merge(resource_file: 'Strings')) }
        expect(File).to exist(File.join(tmpdir, 'Strings.resx'))
        expect(File).to exist(File.join(tmpdir, 'Strings.es.resx'))
      end
    end
  end
end
```

**Step 5: Run all writer tests**

Run: `bundle exec rspec spec/localio/writers/`
Expected: all pass

**Step 6: Commit**

```bash
git add spec/localio/writers/json_writer_spec.rb spec/localio/writers/rails_writer_spec.rb spec/localio/writers/java_properties_writer_spec.rb spec/localio/writers/resx_writer_spec.rb
git commit -m "test: Json, Rails, JavaProperties, and ResX writer tests"
```

---

### Task 14: Integration pipeline test

**Files:**
- Create: `spec/localio_spec.rb`

**Step 1: Write test**

```ruby
require 'json'
require 'localio/string_helper'
require 'localio/term'
require 'localio/segment'
require 'localio/segments_list_holder'
require 'localio/filter'
require 'localio/formatter'
require 'localio/template_handler'
require 'localio/processors/csv_processor'
require 'localio/writers/android_writer'
require 'localio/writers/json_writer'

RSpec.describe 'Localio pipeline' do
  let(:fixture_path) { File.expand_path('fixtures/sample.csv', __dir__) }

  it 'processes CSV and writes Android strings.xml with correct transformations' do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        result = CsvProcessor.load_localizables({}, { path: fixture_path })
        AndroidWriter.write(result[:languages], result[:segments], tmpdir, :smart,
                            { default_language: result[:default_language] })

        content = File.read(File.join(tmpdir, 'values', 'strings.xml'))
        expect(content).to include('<string name="app_name">My App</string>')
        expect(content).to include('&amp; Jerry')   # & converted
        expect(content).to include('Wait…')          # ... converted
        expect(content).to include('%s world')       # %@ converted
        expect(content).to include('<!-- Section General -->')
      end
    end
  end

  it 'processes CSV and writes valid JSON with correct content' do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        result = CsvProcessor.load_localizables({}, { path: fixture_path })
        JsonWriter.write(result[:languages], result[:segments], tmpdir, :smart,
                         { default_language: result[:default_language] })

        data = JSON.parse(File.read(File.join(tmpdir, 'strings-en.json')))
        expect(data['translations']['app_name']).to eq('My App')
        expect(data['meta']['language']).to eq('en')
      end
    end
  end

  it 'applies only filter before writing' do
    result = CsvProcessor.load_localizables({}, { path: fixture_path })
    filtered = Filter.apply_filter(result[:segments], { keys: 'app_' }, nil)
    expect(filtered.map(&:keyword)).to eq(['app_name'])
  end

  it 'applies except filter before writing' do
    result = CsvProcessor.load_localizables({}, { path: fixture_path })
    filtered = Filter.apply_filter(result[:segments], nil, { keys: 'dots_|ampersand_' })
    expect(filtered.map(&:keyword)).not_to include('dots_test', 'ampersand_test')
  end
end
```

**Step 2: Run full test suite**

Run: `bundle exec rspec`
Expected: all tests pass, or failures are clearly gem-install issues (note for Phase 2)

**Step 3: Commit**

```bash
git add spec/localio_spec.rb
git commit -m "test: integration pipeline test (CSV → writers)"
```

---

## Phase 2: Dependency Updates

### Task 15: Audit gem compatibility

**Step 1: Attempt full install and check what breaks**

Run: `bundle install 2>&1`

Run: `bundle exec ruby -e "require 'google_drive'" 2>&1`
Run: `bundle exec ruby -e "require 'simple_xlsx_reader'" 2>&1`
Run: `bundle exec ruby -e "require 'spreadsheet'" 2>&1`
Run: `bundle exec ruby -e "require 'micro-optparse'" 2>&1`

Run: `bundle exec rspec --format progress 2>&1 | tail -20`

Note all failures. These are the targets for the remaining tasks.

---

### Task 16: Update gemspec for Ruby 3.x

**Files:**
- Modify: `localio.gemspec`

**Step 1: Replace gemspec content**

```ruby
# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'localio/version'

Gem::Specification.new do |spec|
  spec.name          = "localio"
  spec.version       = Localio::VERSION
  spec.authors       = ["Nacho Lopez"]
  spec.email         = ["nacho@nlopez.io"]
  spec.description   = %q{Automatic Localizable file generation for multiple platforms}
  spec.summary       = %q{Generates Android, iOS, Rails, JSON, Java Properties, and .NET ResX localization files from spreadsheet sources.}
  spec.homepage      = "http://github.com/mrmans0n/localio"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.executables  << "localize"

  spec.required_ruby_version = ">= 3.0"

  spec.add_development_dependency "rspec",   "~> 3.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake"

  spec.add_dependency "google_drive",        "~> 3.0"
  spec.add_dependency "spreadsheet",         "~> 1.3"
  spec.add_dependency "simple_xlsx_reader",  "~> 2.0"
  spec.add_dependency "nokogiri",            "~> 1.16"
end
```

Note: `micro-optparse` is removed — `bin/localize` will use stdlib `optparse` (Task 17).

**Step 2: Update bundle**

Run: `bundle update`
Expected: updated Gemfile.lock

**Step 3: Run tests and note failures**

Run: `bundle exec rspec --format progress 2>&1 | tail -30`

**Step 4: Commit**

```bash
git add localio.gemspec Gemfile.lock
git commit -m "chore: update gemspec to Ruby 3.x, modernize dependencies"
```

---

### Task 17: Replace micro-optparse with stdlib optparse

**Files:**
- Modify: `bin/localize`

**Step 1: Read current `bin/localize`**

Run: `cat bin/localize`

**Step 2: Replace with stdlib optparse**

```ruby
#!/usr/bin/env ruby
require 'optparse'
require 'localio'

OptionParser.new do |opts|
  opts.banner = 'Usage: localize [Locfile]'
  opts.on('-v', '--version', 'Show version') do
    require 'localio/version'
    puts Localio::VERSION
    exit
  end
end.parse!

Localio.from_cmdline(ARGV)
```

**Step 3: Run tests**

Run: `bundle exec rspec`
Expected: no new failures

**Step 4: Commit**

```bash
git add bin/localize
git commit -m "chore: replace micro-optparse with stdlib optparse"
```

---

### Task 18: Fix google_drive 3.x API changes

**Files:**
- Modify: `lib/localio/processors/google_drive_processor.rb`

The google_drive 3.x API changed significantly:
- No more `Google::APIClient` — uses `googleauth` gem
- `GoogleDrive.login_with_oauth(token)` → `GoogleDrive::Session.from_access_token(token)` or `from_credentials`

**Step 1: Read the new API**

Run: `bundle exec ruby -e "require 'google_drive'; puts GoogleDrive::Session.methods.sort"`

**Step 2: Update the authentication block**

Replace the `begin...rescue` auth block (lines 30–77 in the original) with google_drive 3.x compatible code:

```ruby
puts 'Logging in to Google Drive...'
begin
  config = ConfigStore.new

  if options[:client_token]
    session = GoogleDrive::Session.from_service_account_key(options[:client_token])
  elsif config.has?(:refresh_token)
    session = GoogleDrive::Session.from_config_with_credentials(
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: config.get(:refresh_token)
    )
  else
    session = GoogleDrive::Session.from_config_with_credentials(
      client_id: client_id,
      client_secret: client_secret
    ) do |url|
      puts "1. Open this page:\n#{url}\n"
      puts '2. Enter the authorization code: '
      $stdin.gets.chomp
    end
    config.store(:refresh_token, session.refresh_token)
    config.persist
  end
rescue => e
  raise "Couldn't access Google Drive: #{e.message}"
end
```

Adjust method names based on what `GoogleDrive::Session.methods` shows in Step 1.

**Step 3: Update the GoogleDriveProcessor spec mock**

In `spec/localio/processors/google_drive_processor_spec.rb`, update the `before` block to mock `GoogleDrive::Session` instead of `Google::APIClient` and `GoogleDrive.login_with_oauth`.

**Step 4: Run processor spec**

Run: `bundle exec rspec spec/localio/processors/google_drive_processor_spec.rb`
Expected: all pass

**Step 5: Commit**

```bash
git add lib/localio/processors/google_drive_processor.rb spec/localio/processors/google_drive_processor_spec.rb
git commit -m "fix: update GoogleDriveProcessor for google_drive 3.x API"
```

---

### Task 19: Fix simple_xlsx_reader 2.x API changes (if any)

**Files:**
- Modify: `lib/localio/processors/xlsx_processor.rb` (if needed)

**Step 1: Run the spec and identify failures**

Run: `bundle exec rspec spec/localio/processors/xlsx_processor_spec.rb -f d`

**Step 2: Check changelog for breaking changes**

Run: `gem contents simple_xlsx_reader | xargs grep -l CHANGE 2>/dev/null | head -1 | xargs cat`

Common 2.x change: `SimpleXlsxReader.open(path)` may return a different object. The `book.sheets` array interface is usually stable but sheet row access may differ.

**Step 3: Fix any broken API calls in `xlsx_processor.rb`**

Update the mock in the spec to match the actual 2.x interface if needed.

**Step 4: Run tests**

Run: `bundle exec rspec spec/localio/processors/xlsx_processor_spec.rb`
Expected: all pass

**Step 5: Commit**

```bash
git add lib/localio/processors/xlsx_processor.rb
git commit -m "fix: update XlsxProcessor for simple_xlsx_reader 2.x"
```

---

### Task 20: Final Ruby 3.x compatibility sweep

**Step 1: Run full suite and list all failures**

Run: `bundle exec rspec --format documentation 2>&1 | grep -E "FAILED|Error" | head -30`

**Common Ruby 3.x issues to look for:**

- `Hash.new('default')` used as a hash with string default value — the `languages = Hash.new('languages')` in processors may cause unexpected behavior when missing keys return `'languages'` instead of nil. This is existing code behaviour, not a breakage, but verify tests still pass.
- Keyword argument separation: methods that used hash splatting (`**`) — check if any `options` hash calls trigger the "last hash argument" warning.
- `$LOAD_PATH` and encoding — usually fine in 3.x.
- `String#encode` changes — watch for encoding errors in CSV/XLS parsing with non-ASCII characters (the `Mi Aplicación` fixture tests this).

**Step 2: Fix any remaining failures one by one**

For each failure, read the error, identify the cause, fix minimally.

**Step 3: Run full suite — must be green**

Run: `bundle exec rspec`
Expected: all tests pass

**Step 4: Commit any fixes**

```bash
git add -p
git commit -m "fix: Ruby 3.x compatibility fixes"
```

---

### Task 21: Version bump and final verification

**Files:**
- Modify: `lib/localio/version.rb`
- Modify: `README.md` (Ruby version requirement)

**Step 1: Bump the patch version**

In `lib/localio/version.rb`, change `VERSION = "0.1.7"` to `VERSION = "0.1.8"`.

**Step 2: Update README**

Find the Ruby version requirement mention in `README.md` and update it from `>= 1.9.2` to `>= 3.0`.

**Step 3: Final full suite run**

Run: `bundle exec rspec --format documentation`
Expected: all tests documented and passing

**Step 4: Commit**

```bash
git add lib/localio/version.rb README.md
git commit -m "chore: bump version to 0.1.8, require Ruby 3.0+"
```
