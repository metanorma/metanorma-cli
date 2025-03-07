require "spec_helper"

RSpec.describe Metanorma::Cli::Compiler do
  describe ".compile" do
    it "compile a document to desire formats" do
      VCR.use_cassette "workgroup_fetch" do
        compiler = double("Metanorma::Compile", compile: nil, errors: [])
        allow(Metanorma::Compile).to receive(:new).and_return(compiler)

        Metanorma::Cli::Compiler.compile(sample_asciidoc_file, attributes)

        expect(compiler).to have_received(:compile).with(
          sample_asciidoc_file, attributes
        )
      end
    end

    # @TODO: What exactly are we testing here?
    # The script should exit with non zero status when errors like following
    # occur:
    #   [metanorma] Error: xmlrfc2 format is not supported for this standard.
    #   [metanorma] Error: nits format is not supported for this standard.
    # See issue #151.
    #
    it "compile with errors" do
      skip "Skipping for now, will get back to it soon!"

      # Try to update metanorma gem
      VCR.use_cassette "workgroup_fetch" do
        expect do
          Metanorma::Cli.start(["spec/fixtures/mn-samples-ietf-antioch.adoc",
                                "--no-install-fonts"])
        end.to raise_error SystemExit

        delete_file_if_exist("mn-samples-ietf-antioch.err")
        delete_file_if_exist("mn-samples-ietf-antioch.rfc.xml")
        delete_file_if_exist("mn-samples-ietf-antioch.")
      end
    end

    it "write files to specified output dir" do
      VCR.use_cassette "workgroup_fetch" do
        Dir.mktmpdir("rspec-") do |dir|
          Metanorma::Cli.start(["spec/fixtures/sample-file.adoc", "-o", dir,
                                "--no-install-fonts"])
          expect(File.exist?("#{dir}/sample-file.html")).to be true
          expect(File.exist?("#{dir}/sample-file.xml")).to be true
          expect(File.exist?("#{dir}/sample-file.presentation.xml")).to be true
        end
      end
    end
  end

  def attributes
    {
      type: "iso",
      extract_type: [],
      extension_keys: [],
      install_fonts: false,
      progress: false,
    }
  end

  def sample_asciidoc_file
    @sample_asciidoc_file ||= Metanorma::Cli.root_path.join(
      "spec",
      "fixtures",
      "sample-file.adoc",
    ).to_s
  end

  def delete_file_if_exist(filename)
    filepath = Metanorma::Cli.root_path.join("spec", "fixtures", filename).to_s
    File.delete(filepath) if File.exist?(filepath)
  end
end
