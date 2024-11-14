require "tmpdir"
require "pathname"
require_relative "spec_helper"

RSpec.describe Metanorma do
  before :all do
    spec_assets_path = output_path.join("spec")

    FileUtils.mkdir_p(spec_assets_path)
    FileUtils.cp_r("spec/assets", spec_assets_path)
    system "bundle install"
  end

  after :each do
    cleanup_test_files
  end

  it "processes metanorma options inside Asciidoc" do
    create_clean_test_files ASCIIDOC_PREAMBLE_HDR

    compile_doc(source_file)

    expect_files_to_exists("test.xml", "test.html")
    expect_files_to_not_exists("test.doc", "test.alt.html")
    expect(file_content("test.xml")).to include("</iso-standard>")
  end

  it "processes an asciidoc ISO document" do
    mock_pdf
    mock_sts
    create_clean_test_files ASCIIDOC_BLANK_HDR
    compile_doc(source_file, "-t iso")

    expect_files_to_exists("test.xml", "test.doc", "test.html", "test.alt.html")
  end

  it "processes all extensions of an asciidoc ISO document" do
    mock_pdf
    mock_sts
    create_clean_test_files ASCIIDOC_BLANK_HDR
    compile_doc(source_file, "-t iso -x all")

    expect_files_to_exists("test.xml", "test.doc", "test.html", "test.alt.html")
  end

  it "processes specific extensions of an asciidoc ISO document" do
    create_clean_test_files ASCIIDOC_BLANK_HDR
    compile_doc(source_file, "-t iso -x xml,doc")

    expect_files_to_exists("test.xml", "test.doc")
    expect_files_to_not_exists("test.html", "test.alt.html")
    expect(file_content("test.xml")).to include("</iso-standard>")
  end

  it "extracts isodoc options from asciidoc file" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR

    compile_doc(source_file, "-t iso -x html")
    html = file_content("test.html")

    expect(html).to include "font-family: body-font;"
    expect(html).to include "font-family: header-font;"
    expect(html).to include "font-family: monospace-font;"
  end

  it "wraps HTML output" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    compile_doc(source_file, "-w -t iso -x html")

    expect_files_to_exists("test/test.html")
  end

  it "data64 encodes images" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    compile_doc(source_file, "-d -t iso -x html")

    expect(file_content("test.html")).to include("data:image")
  end

  it "exports bibdata" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    filename = "testrelaton.xml"
    compile_doc(source_file, "-R #{file_path(filename)} -t iso -x html")

    expect(file_content(filename)).to include('<bibdata type="standard">')
  end

  it "exports bibdata as rxl" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    compile_doc(source_file, "-x rxl -t iso")

    expect(file_content("test.rxl")).to include('<bibdata type="standard">')
  end

  it "non-zero exit code when metanorma compile for missing file" do
    expect(compile_doc("not_existing.adoc")).to be false
  end

  it "warns when no standard type provided" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    stdout = `metanorma #{source_file} --no-install-fonts`
    expect(stdout).to include "Please specify a standard type"
  end

  it "warns when bogus standard type requested" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    `metanorma -t bogus_format #{source_file}`
    expect($?.exitstatus).not_to be == 0
  end

  it "warns when bogus format requested" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR
    stdout = `metanorma -t iso -f bogus_format #{source_file}`
    expect(stdout).to include("Only source file format currently supported")
  end

  it "warns when no file provided" do
    stdout = `metanorma -t iso -x html`
    expect(stdout).to include "Need to specify a file to process"
  end

  it "gives version information" do
    stdout = `metanorma -v -t iso`
    expect(stdout).to match(/Metanorma::Iso \d/)
  end

  it "exports assets" do
    create_clean_test_files ASCIIDOC_CONFIGURED_HDR

    compile_doc(source_file, "-x xml -t iso -e extract,sourcecode")
    output_file = "extract/sourcecode/sourcecode-0000.txt"

    expect_files_to_not_exists("extract/image/image-0000.png")
    expect(file_content(output_file, temp: false)).to eq(code_block)
  end

  it "config handle not existing values in global config" do
    stdout = `metanorma config get --global cli.not_exists`
    expect(stdout).to eq("nil\n")
  end

  it "config test set global config" do
    `metanorma config set --global cli.test true`
    stdout = `metanorma config get --global cli.test`
    expect(stdout).to eq("true\n")
    `metanorma config unset --global cli.test`
    stdout = `metanorma config get --global cli.test`
    expect(stdout).to eq("nil\n")
  end

  it "config test set local value" do
    Dir.mktmpdir("rspec-") do |dir|
      Dir.chdir(dir) do
        `metanorma config set cli.not_exists true`
        stdout = `metanorma config get cli.not_exists`
        expect(stdout).to eq("true\n")
      end
    end
  end

  it "config handle not existing values in local config" do
    Dir.mktmpdir("rspec-") do |dir|
      Dir.chdir(dir) do
        expect(`metanorma config get cli.not_exists`).to eq("nil\n")
      end
    end
  end

  it "metanorma-cli accept --no-progress argument" do
    create_clean_test_files ASCIIDOC_BLANK_HDR
    compile_doc(source_file, "-t iso -x xml,doc --no-progress")
  end

  # COMMENT context "with -r option specified" do
  # moving this text to end of suite instead
  context "with -r option specified" do
    it "with -r option specified loads the libary and compile document" do
      create_clean_test_files ASCIIDOC_PREAMBLE_HDR
      system "bundle install"
      compile_doc(source_file, "-t iso -r metanorma-iso --no-install-fonts")

      expect_files_to_exists("test.xml", "test.html")
      expect_files_to_not_exists("test.doc", "test.alt.html")
      expect(file_content("test.xml")).to include("</iso-standard>")
    end
  end

  %w[rfc sts].each do |type|
    it "metanorma-cli convert #{type}" do
      input_fname = "mnconvert_#{type}.xml"
      input = File.join(File.dirname(__FILE__), "assets", input_fname)
      Dir.mktmpdir("rspec-") do |dir|
        Dir.chdir(dir) do
          tmp_input = File.join(Dir.pwd, input_fname)
          result = File.join(Dir.pwd, "result.xml")
          FileUtils.cp input, tmp_input
          `metanorma convert #{tmp_input} --output-file #{result} --debug`
          expect_files_to_exists(result)
        end
      end
    end
  end

  def code_block
    <<~OUTPUT.strip
      def ruby(x)
        if x < 0 && x > 1
          return
        end
      end
    OUTPUT
  end

  def file_content(file, temp: true)
    File.read(file_path(file, temp: temp))
  end

  def cleanup_test_files
    FileUtils.rm_f(Dir.glob(file_path("test**")))
  end

  def file_path(file, temp: true)
    temp ? output_path.join(file) : file
  end

  def source_file
    @source_file ||= output_path.join("test.adoc")
  end

  def create_clean_test_files(content)
    cleanup_test_files
    File.write(source_file, content, encoding: "UTF-8")
  end

  def output_path
    @output_path ||= Pathname.new(Dir.mktmpdir("metanorma_tests"))
  end

  def compile_doc(source_file, options = "")
    system("metanorma compile #{options} #{source_file} --no-install-fonts")
  end

  def expect_files_to_exists(*files)
    files.each { |file| expect(File.exist?(file_path(file))).to be_truthy }
  end

  def expect_files_to_not_exists(*files)
    files.each { |file| expect(File.exist?(file_path(file))).to be_falsey }
  end
end
