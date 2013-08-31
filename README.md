# Localio

Localio generates automatically localizable files for many platforms like Rails, Android, iOS, etc., using a centralized spreadsheet as source. The spreadsheet can be from Google Drive or a simple Excel file.

## Installation

Add this line to your application's Gemfile:

    gem 'localio'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install localio

## Usage

You have to create a custom file, Locfile, similar to Rakefile or Gemfile, with some information for this to work. Also you must have some spreadsheet with a particular format, either in Google Drive or in XLS format.

In your Locfile directory you can then execute

````
localize
````

and your localizable files will be created with the parameters specified in the Locfile.

### Locfile

A minimal `Locfile` example could be:

````ruby
platform :ios

output_path 'out/'

source :google_drive,
    :spreadsheet => '[Localizables] My Project!',
    :login => 'your_email@gmail.com',
    :password => 'your_password'
````

This would connect localio to your Google Drive and process the spreadsheet with title "[Localizables] My Project!".

The list of possible commands is this.

Option                      | Description                                                      | Default
----------------------------|------------------------------------------------------------------|--------
`platform`                  | (Req.) Target platform for the localizable files.                | ---
`source`                    | (Req.) Information on where to find the spreadsheet w/ the info  | ---
`output_path`               | (Req.) Target directory for the localizables.                    | `out/`
`formatting`                | The formatter that will be used for key processing.              | `smart`


#### Supported platforms

* `:android` for Android string.xml files.
* `:ios` for iOS Localizable.strings files.
* `:rails` for Rails YAML files.
* `:json` for an easy JSON format for localizables.

#### Supported sources

* `:google_drive` will connect to Google Drive.
* `:xls` will use a local XLS file.

#### Key formatters

* `:none` for no formatting.
* `:snake_case` for snake case formatting (ie "this_kind_of_keys").
* `:camel_case` for camel case formatting (ie "thisKindOfKeys").
* `:smart` use a different formatting depending on the platform.

### The Spreadsheet

You have a basic example in this Google Drive link: [https://docs.google.com/spreadsheet/ccc?key=0AmX_w4-5HkOgdFFoZ19iSUlRSERnQTJ4NVZiblo2UXc&usp=sharing](https://docs.google.com/spreadsheet/ccc?key=0AmX_w4-5HkOgdFFoZ19iSUlRSERnQTJ4NVZiblo2UXc&usp=sharing)

You just have to duplicate and save to your account, or download and save it as XLS file.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
