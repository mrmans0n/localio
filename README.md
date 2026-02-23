# Localio

Localio generates automatically localizable files for many platforms like Rails, Android, iOS, Java .properties files and JSON files using a centralized spreadsheet as source. The spreadsheet can be in Google Drive or a simple local Excel file.

## Installation

Add this line to your application's Gemfile:

    gem 'localio'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install localio

## Usage

You have to create a custom file, Locfile, similar to Rakefile or Gemfile, with some information for this to work. Also you must have some spreadsheet with a particular format, either in Google Drive, CSV files or in Excel (XLS or XLSX) format.

In your Locfile directory you can then execute

````
localize
````

and your localizable files will be created with the parameters specified in the Locfile. 

You can also specify in the first parameter a file with another name, and it will work as well.

### The Spreadsheet

You will need a little spreadsheet with all the localization literals and their intended keys for internal use while coding.

There is a basic example in this Google Drive link: [https://docs.google.com/spreadsheet/ccc?key=0AmX_w4-5HkOgdFFoZ19iSUlRSERnQTJ4NVZiblo2UXc&usp=sharing](https://docs.google.com/spreadsheet/ccc?key=0AmX_w4-5HkOgdFFoZ19iSUlRSERnQTJ4NVZiblo2UXc&usp=sharing). You just have to duplicate and save to your account, or download and save it as XLS file.

**NOTE** Localio will only search for translations on the first worksheet of the spreadsheet. 

### Locfile

A minimal `Locfile` example could be:

````ruby
platform :ios

output_path 'my_output_path/'

source :xlsx,
       :path => 'my_translations.xlsx'
````

This would read from `my_translations.xlsx` and write iOS localizable files to `my_output_path/`.

The list of possible commands is this.

Option                      | Description                                                      | Default
----------------------------|------------------------------------------------------------------|--------
`platform`                  | (Req.) Target platform for the localizable files.                | `nil`
`source`                    | (Req.) Information on where to find the spreadsheet w/ the info  | `nil`
`output_path`               | (Req.) Target directory for the localizables.                    | `out/`
`formatting`                | The formatter that will be used for key processing.              | `smart`
`except`                    | Filter applied to the keys, process all except the matches.      | `nil`
`only`                      | Filter applied to the keys, only process the matches.            | `nil`

#### Supported platforms

* `:android` for Android string.xml files. The `output_path` needed is the path for the `res` directory.
* `:ios` for iOS Localizable.strings files. The `output_path` needed is base directory where `en.lproj/` and such would go. Also creates header file with Objective-C macros.
* `:swift` for iOS Localizable.strings files. The `output_path` needed is base directory where `en.lproj/` and such would go. Also creates source file with Swift constants.
* `:rails` for Rails YAML files. The `output_path` needed is your `config/locales` directory.
* `:json` for an easy JSON format for localizables. The `output_path` is yours to decide :)
* `:java_properties` for .properties files used mainly in Java. Files named language_(lang).properties will be generated in `output_path`'s root directory.
* `:resx` for .resx files used by .NET projects, e.g. Windows Forms, Windows Phone or Xamarin.
* `:twine` for [Twine](https://github.com/scelis/twine)-compatible `strings.txt` files containing all languages in a single file. The `output_path` is the directory where the file will be written.

#### Extra platform parameters


#####  `avoid_lang_downcase`

By default, language codes are downcased. We can set `:avoid_lang_downcase => true` to avoid this behavior.

##### iOS - :ios, :swift

We can opt-out from the constants/macros. We will simple need to add `:create_constants => false`. By default, if omitted, the constants will be always created. It's a good practice to have a compile-time check of the existence of your keys; but if you don't like it it's fine.

Example:

````ruby
platform :ios, :create_constants => false
# ... rest of your Locfile ...
````

##### ResX - :resx

The default resource file name is `Resources.resx`. We can set a different base name using the `:resource_file` option.

````ruby
# Generate WebResources.resx, WebResources.es.resx, etc.
platform :resx, :resource_file => "WebResources" 

# ... rest of your Locfile ...
````

##### Twine - :twine

By default the output file is named `strings.txt`. Use `:output_file` to override:

````ruby
platform :twine, :output_file => 'MyApp.strings'
````

#### Supported sources

##### Google Drive

`source :google_drive` will get the translation strings from Google Drive.

Two authentication methods are supported: **OAuth2** (for personal accounts) and **service accounts** (for automated/CI use).

Option                      | Description
----------------------------|-------------------------------------------------------------------------
`:spreadsheet`              | (Req.) Title of the spreadsheet you want to use. Can be a partial match.
`:sheet`                    | (Req.) Index number (starting with 0) or name of the sheet w/ the data
`:client_id`                | Your Google OAuth2 Client ID. Required unless using `:client_token`.
`:client_secret`            | Your Google OAuth2 Client Secret. Required unless using `:client_token`.
`:client_token`             | Path to a service account JSON key file. Alternative to OAuth2.

###### Option A: OAuth2 (personal account)

1. Go to the [Google Cloud Console](https://console.cloud.google.com/), create a project and enable the **Google Drive API**.
2. Under **APIs & Services → Credentials**, create an **OAuth client ID**. Choose **Desktop app** as the application type.
3. Download or copy your **Client ID** and **Client Secret**.

Add them to your Locfile:

```ruby
source :google_drive,
       :spreadsheet => '[Localizables] My Project',
       :client_id => ENV['GOOGLE_CLIENT_ID'],
       :client_secret => ENV['GOOGLE_CLIENT_SECRET']
```

The first time you run `localize`, you will be prompted to open a URL in your browser, grant access to your Drive, and paste the authorization code back into the terminal. After that, the refresh token is saved to `~/.localio_gdrive_config.json` and subsequent runs authenticate automatically.

**NOTE** As it is a very bad practice to put your sensitive information in a plain file, it is **strongly recommended** to use environment variables. Export them from your shell profile (`.zshrc`, `.bashrc`, etc.):

```bash
export GOOGLE_CLIENT_ID="your_client_id"
export GOOGLE_CLIENT_SECRET="your_client_secret"
```

###### Option B: Service account (automated/CI use)

1. In the [Google Cloud Console](https://console.cloud.google.com/), create a **Service Account** under **APIs & Services → Credentials**.
2. Download the JSON key file.
3. Share the target spreadsheet with the service account's email address (found in the JSON file under `client_email`).

```ruby
source :google_drive,
       :spreadsheet => '[Localizables] My Project',
       :client_token => 'path/to/service_account_key.json'
```

##### XLS

`source :xls` will use a local XLS file. In the parameter's hash you should specify a `:path`.
You may specify a `sheet` parameter, otherwise the first sheet will be used.

Option                      | Description
----------------------------|-------------------------------------------------------------------------
`:path`                     | (Req.) Path for your XLS file.
`:sheet`                    | (Optional) Index number (starting with 0) or name of the sheet w/ the data

````ruby
source :xls,
       :path => 'YourExcelFileWithTranslations.xls',
       :sheet => 'Master Translation Data'
````

##### XLSX

`source :xlsx` will use a local XLSX file. In the parameter's hash you should specify a `:path`.
You may specify a `sheet` parameter, otherwise the first sheet will be used.

Option                      | Description
----------------------------|-------------------------------------------------------------------------
`:path`                     | (Req.) Path for your XLSX file.
`:sheet`                    | (Req.) Index number (starting with 0) or name of the sheet w/ the data

````ruby
source :xlsx,
       :path => 'YourExcelFileWithTranslations.xlsx',
       :sheet => 'Master Translation Data'
````

##### CSV

`source :csv` will use a local CSV file. In the parameter's hash you should specify a `:path`.

Option                      | Description
----------------------------|-------------------------------------------------------------------------
`:path`                     | (Req.) Path for your CSV file.
`:column_separator`         | By default it is ',', but you can change it with this parameter

In this example we specify tabs as separators for translation columns. The `:column_separator` is not needed if the separator is a comma and could be removed.

````ruby
source :csv,
       :path => 'YourCSVTranslations.csv',
       :column_separator => '\t'
````

#### Key formatters

If you don't specify a formatter for keys, :smart will be used.

* `:none` for no formatting.
* `:snake_case` for snake case formatting (ie "this_kind_of_key").
* `:camel_case` for camel case formatting (ie "ThisKindOfKey").
* `:smart` use a different formatting depending on the platform.

Here you have some examples on how the behavior would be:

Platform             | "App name"   | "ANOTHER_KIND_OF_KEY"
---------------------|--------------|----------------------
`:none`              | `App name`   | `ANOTHER_KIND_OF_KEY`
`:snake_case`        | `app_name`   | `another_kind_of_key`
`:camel_case`        | `appName`    | `AnotherKindOfKey`
`:smart` (ios/swift) | `_App_name`  | `_Another_kind_of_key`
`:smart` (android)   | `app_name`   | `another_kind_of_key`
`:smart` (ruby)      | `app_name`   | `another_kind_of_key`
`:smart` (json)      | `app_name`   | `another_kind_of_key`
`:smart` (resx)      | `AppName`    | `AnotherKindOfKey`

Example of use:

````ruby
formatting :camel_case
````

Normally you would want a smart formatter, because it is adjusted (or tries to) to the usual code conventions of each platform for localizable strings.

### Advanced options

#### Filtering content

We can establish filters to the keys by using regular expressions.

The exclusions are managed with the `except` command. For example, if we don't want to include the translations where the key has the "[a]" string, we could include this in the Locfile.

````ruby
except :keys => '[\[][a][\]]'
````

We can filter inversely too, with the command `only`. For example, if we only want the translations that contain the '[a]' token, we should use:

````ruby
only :keys => '[\[][a][\]]'
````

#### Overriding default language

This only makes sense with `platform :android` and `platform :resx` at the moment. If we want to override (for whatever reason) the default language flag in the source spreadsheet, we can use `:override_default => 'language'`.

For example, if we wanted to override the default (english) and use spanish instead, we could do this:

```ruby
platform :android, :override_default => 'es'
```

## Contributing

Please read the [contributing guide](https://github.com/mrmans0n/localio/blob/master/CONTRIBUTING.md).
