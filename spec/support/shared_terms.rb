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
