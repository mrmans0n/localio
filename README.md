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

### The Spreadsheet

You will need a little spreadsheet with all the localization literals and their intended keys for internal use while coding.

There is a basic example in this Google Drive link: [https://docs.google.com/spreadsheet/ccc?key=0AmX_w4-5HkOgdFFoZ19iSUlRSERnQTJ4NVZiblo2UXc&usp=sharing](https://docs.google.com/spreadsheet/ccc?key=0AmX_w4-5HkOgdFFoZ19iSUlRSERnQTJ4NVZiblo2UXc&usp=sharing). You just have to duplicate and save to your account, or download and save it as XLS file.

### Locfile

A minimal `Locfile` example could be:

````ruby
platform :ios

output_path 'out/'

source :google_drive,
       :spreadsheet => '[Localizables] My Project!',
       :login => 'your_email@gmail.com',
       :password => 'your_password'

formatting :smart # This is optional, formatting :smart is used by default.
````

This would connect localio to your Google Drive and process the spreadsheet with title "[Localizables] My Project!".

The list of possible commands is this.

Option                      | Description                                                      | Default
----------------------------|------------------------------------------------------------------|--------
`platform`                  | (Req.) Target platform for the localizable files.                | `nil`
`source`                    | (Req.) Information on where to find the spreadsheet w/ the info  | `nil`
`output_path`               | (Req.) Target directory for the localizables.                    | `out/`
`formatting`                | The formatter that will be used for key processing.              | `smart`

#### Supported platforms

* `:android` for Android string.xml files. The `output_path` needed is the path for the `res` directory.
* `:ios` for iOS Localizable.strings files. The `output_path` needed is base directory where `en.lproj/` and such would go.
* `:rails` for Rails YAML files. The `output_path` needed is your `config/locales` directory.
* `:json` for an easy JSON format for localizables. The `output_path` is yours to decide :)

#### Supported sources

##### Google Drive

`source :google_drive` will get the translation strings from Google Drive.

You will have to provide some required parameters too. Here is a list of all the parameters.

Option                      | Description
----------------------------|-------------------------------------------------------------------------
`:spreadsheet`              | (Req.) Title of the spreadsheet you want to use. Can be a partial match.
`:login`                    | (Req.) Your Google login.
`:password`                 | (Req.) Your Google password.

**NOTE** As it is a very bad practice to put your login and your password in a plain file, specially when you would want to upload your project to some repository, it is **VERY RECOMMENDED** that you use environment variables in here. Ruby syntax is accepted so you can use `ENV['GOOGLE_LOGIN']` and `ENV['GOOGLE_PASSWORD']` in here.

For example, this.

````ruby
source :google_drive,
       :spreadsheet => '[Localizables] My Project!',
       :login => ENV['GOOGLE_LOGIN'],
       :password => ENV['GOOGLE_PASSWORD']
````

And in your .bashrc (or .bash_profile, .zshrc or whatever), you could export those environment variables like this:

````ruby
export GOOGLE_LOGIN="your_login"
export GOOGLE_PASSWORD="your_password"
````

##### XLS

`source :xls` will use a local XLS file. In the parameter's hash you should specify a `:path`.

Option                      | Description
----------------------------|-------------------------------------------------------------------------
`:path`                     | (Req.) Path for your XLS file.

````ruby
source :xls,
       :path => 'YourExcelFileWithTranslations.xls'
````

##### XLSX

Currently XLSX is not supported though the code is there (not tested, though) and it will be included in a future release.

#### Key formatters

If you don't specify a formatter for keys, :smart will be used.

* `:none` for no formatting.
* `:snake_case` for snake case formatting (ie "this_kind_of_key").
* `:camel_case` for camel case formatting (ie "ThisKindOfKey").
* `:smart` use a different formatting depending on the platform.

Here you have some examples on how the behavior would be:

Platform           | "App name"   | "ANOTHER_KIND_OF_KEY"
-------------------|--------------|----------------------
`:none`            | App name     | ANOTHER_KIND_OF_KEY
`:snake_case`      | app_name     | another_kind_of_key
`:camel_case`      | appName      | AnotherKindOfKey
`:smart` (ios)     | _App_name    | _Another_kind_of_key
`:smart` (android) | app_name     | another_kind_of_key
`:smart` (ruby)    | app_name     | another_kind_of_key
`:smart` (json)    | app_name     | another_kind_of_key

Example of use:

````ruby
formatting :camel_case
````

Normally you would want a smart formatter, because it is adjusted (or tries to) to the usual code conventions of each platform for localizable strings.

## Contributing

Please read the [contributing guide](https://github.com/mrmans0n/localio/blob/master/CONTRIBUTING.md).
