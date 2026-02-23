# google_drive transitively loads nokogiri.  Nokogiri is now built for arm64
# and loads correctly, so we no longer need to stub it out.  We only stub
# google_drive itself (which requires OAuth flow and network access) by:
#   1. Defining minimal stub modules for GoogleDrive before anything tries to
#      reference them.
#   2. Pre-populating $LOADED_FEATURES with the google_drive gem paths so that
#      every subsequent `require 'google_drive'` is treated as already loaded.
# All runtime calls are intercepted by RSpec doubles.

module GoogleDrive
  module Session
    def self.from_config(_config, _opts = {}); end
    def self.from_service_account_key(_path, _scope = nil); end
  end
end

begin
  _gd_base = '/Volumes/Workspace/localio/.worktrees/modernization/' \
             'vendor/bundle/ruby/3.3.0/gems/google_drive-3.0.7/lib'
  Dir["#{_gd_base}/**/*.rb"].sort.each do |f|
    $LOADED_FEATURES << f unless $LOADED_FEATURES.include?(f)
  end
  ["#{_gd_base}/google_drive.rb"].each do |f|
    $LOADED_FEATURES << f unless $LOADED_FEATURES.include?(f)
  end
end

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

    # Mock the google_drive 3.x session creation method used by the processor.
    # from_config is used for the OAuth2 client_id/client_secret flow.
    allow(GoogleDrive::Session).to receive(:from_config).and_return(session_double)

    # Allow File.file? to return false for the :client_token option in OAuth tests
    # so the processor takes the from_config path (not the service-account path).
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with('token').and_return(false)
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
