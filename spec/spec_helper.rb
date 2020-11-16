require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
end

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "bundler/setup"
require "rspec-command"
require "metanorma/cli"
require "fileutils"
require "rexml/document"

Dir["./spec/support/**/*.rb"].sort.each { |file| require file }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  config.include Metanorma::ConsoleHelper
  config.include Metanorma::Helper

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    tmp_dir = Pathname.new("./tmp")
    FileUtils.mkdir_p(tmp_dir) unless tmp_dir.exist?

    # Disable http authentication
    ENV["GIT_TERMINAL_PROMPT"] = "0"
  end

  config.after(:suite) do
    ENV["GIT_TERMINAL_PROMPT"] = "1"
  end

  config.include RSpecCommand
end

def xmlpp(x)
  s = ""
  f = REXML::Formatters::Pretty.new(2)
  f.compact = true
  f.write(REXML::Document.new(x),s)
  s
end

ASCIIDOC_BLANK_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

HDR

ASCIIDOC_PREAMBLE_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:
      :mn-document-class: iso
      :mn-output-extensions: xml,html

HDR

ASCIIDOC_CONFIGURED_HDR = <<~"HDR"
      = Document title
      Author
      :docfile: test.adoc
      :docnumber: 123
      :nodoc:
      :novalid:
      :no-isobib:
      :script: script.html
      :body-font: body-font
      :header-font: header-font
      :monospace-font: monospace-font
      :title-font: title-font
      :i18nyaml: i18n.yaml
      :stem:

      == Scope
      image::spec/assets/rice_image1.png[]

      stem:[1/r]

      [source,ruby]
      ----
      def ruby(x)
        if x < 0 && x > 1
          return
        end
      end
      ----
HDR

ISOXML_BLANK_HDR = <<~"HDR"
<?xml version="1.0" encoding="UTF-8"?>
<iso-standard xmlns="http://riboseinc.com/isoxml">
<bibdata type="article">
  <title>
  </title>
  <title>
  </title>
  <docidentifier>
    <project-number>ISO </project-number>
  </docidentifier>
  <contributor>
    <role type="author"/>
    <organization>
      <name>International Organization for Standardization</name>
      <abbreviation>ISO</abbreviation>
    </organization>
  </contributor>
  <contributor>
    <role type="publisher"/>
    <organization>
      <name>International Organization for Standardization</name>
      <abbreviation>ISO</abbreviation>
    </organization>
  </contributor>
  <script>Latn</script>
  <status>
    <stage>60</stage>
    <substage>60</substage>
  </status>
  <copyright>
    <from>#{Time.new.year}</from>
    <owner>
      <organization>
        <name>International Organization for Standardization</name>
        <abbreviation>ISO</abbreviation>
      </organization>
    </owner>
  </copyright>
  <editorialgroup>
    <technical-committee/>
    <subcommittee/>
    <workgroup/>
  </editorialgroup>
</bibdata>
</iso-standard>
HDR

