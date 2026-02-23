# google_drive transitively loads nokogiri, whose native extension is compiled
# for x86_64 and fails to dlopen on this arm64 host.  We prevent the real gem
# files from ever being evaluated by:
#   1. Defining minimal stub modules for GoogleDrive, Google::APIClient, and
#      ConfigStore before anything tries to reference them.
#   2. Pre-populating $LOADED_FEATURES with the absolute gem paths so that
#      every subsequent `require 'google_drive'` (including the one at the top
#      of google_drive_processor.rb) is treated as already loaded.
# All runtime calls are intercepted by RSpec doubles.

module GoogleDrive
  def self.login_with_oauth(_token); end
end

module Google
  class APIClient
    def self.new(**_opts); end
  end
end

class ConfigStore
  def initialize; end
  def has?(_key); false; end
  def get(_key); nil; end
  def store(_key, _val); end
  def persist; end
end

begin
  _gd_base  = '/Volumes/Workspace/localio/.worktrees/modernization/' \
               'vendor/bundle/ruby/2.6.0/gems/google_drive-1.0.6/lib'
  _nok_base = '/Volumes/Workspace/localio/.worktrees/modernization/' \
               'vendor/bundle/ruby/2.6.0/gems/nokogiri-1.13.10-x86_64-darwin/lib'
  _gd_files = Dir["#{_gd_base}/**/*.rb"].sort
  _nok_files = Dir["#{_nok_base}/**/*.rb"].sort
  (_gd_files + _nok_files).each do |f|
    $LOADED_FEATURES << f unless $LOADED_FEATURES.include?(f)
  end
  # Top-level require entry points
  ["#{_gd_base}/google_drive.rb", "#{_nok_base}/nokogiri.rb"].each do |f|
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
