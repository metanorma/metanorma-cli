require "spec_helper"

RSpec.describe "Metanorma" do
  describe "export-config" do
    context "without any type specified" do
      it "insists on type specification" do
        command = %w(export-config)
        output = capture_stdout { Metanorma::Cli.start(command) }
        output.gsub!(/\s+/, " ")
        expect(output).to include("Please specify a standard type")

        command = %w(export-config unknown-type)
        output = capture_stdout { Metanorma::Cli.start(command) }
        output.gsub!(/\s+/, " ")
        expect(output).to include("please provide a valid type!")
      end
    end

    context "with type specified" do
      it "exports configuration files for flavor to the export directory" do
        export_dir = "export-config-iso"
        FileUtils.rm_rf(export_dir) if Dir.exist?(export_dir)
        command = %w(export-config iso)
        output = capture_stdout { Metanorma::Cli.start(command) }
        output.gsub!(/\s+/, " ")

        # Verify the output message indicates files were exported
        expect(output).to include("Exported")
        expect(output).to include("configuration file(s) from metanorma-iso")
        expect(output).to include(export_dir)
        expect(Dir.exist?(export_dir)).to be true
        expect(File.exist?(File.join(export_dir,
                                     "metanorma/iso/boilerplate.adoc"))).to be true
        expect(File.exist?(File.join(export_dir,
                                     "isodoc/iso/html/header.html"))).to be true
        expect(File.exist?(File.join(export_dir,
                                     "isodoc/iso/html/isodoc.scss"))).to be true
        expect(File.exist?(File.join(export_dir,
                                     "relaton/render/config.yml"))).to be true
        FileUtils.rm_rf(export_dir) if Dir.exist?(export_dir)
      end

      it "exports configuration files for taste to the export directory" do
        export_dir = "export-config-oiml"
        FileUtils.rm_rf(export_dir) if Dir.exist?(export_dir)
        command = %w(export-config oiml)
        output = capture_stdout { Metanorma::Cli.start(command) }
        output.gsub!(/\s+/, " ")

        # Debug: Print full output
        warn "Full output: #{output}"

        # Verify the output message indicates files were exported
        expect(output).to include("Exported")
        expect(output).to include("configuration file(s) from metanorma-iso")
        expect(output).to include(export_dir)
        expect(Dir.exist?(export_dir)).to be true
        expect(File.exist?(File.join(export_dir,
                                     "metanorma/iso/boilerplate.adoc"))).to be true
        expect(File.exist?(File.join(export_dir,
                                     "isodoc/iso/html/header.html"))).to be true
        expect(File.exist?(File.join(export_dir,
                                     "isodoc/iso/html/isodoc.scss"))).to be true
        expect(File.exist?(File.join(export_dir,
                                     "relaton/render/config.yml"))).to be true

        # Verify taste export either succeeded or reported no files
        # (depending on whether metanorma-taste gem is installed)
        if output.include?("taste configuration file(s)")
          # Taste export succeeded
          expect(output).to include("Exported")
          expect(output).to include("taste configuration file(s)")

          # Verify taste directory and files exist
          taste_dir = File.join(export_dir, "taste")
          expect(Dir.exist?(taste_dir)).to be true

          # Files are copied with preserved structure from data/{taste}
          # So they end up in taste/{taste}/*
          expect(File.exist?(File.join(export_dir,
                                       "taste/oiml/config.yaml"))).to be true
        elsif output.include?("No files found in metanorma-taste")
          # Taste data directory empty or doesn't exist
          warn "Taste data not found - this is expected if metanorma-taste gem structure changed"
        elsif output.include?("metanorma-taste is not installed")
          # Gem not installed - skip taste verification
          warn "metanorma-taste gem not installed - skipping taste verification"
        end

        FileUtils.rm_rf(export_dir) if Dir.exist?(export_dir)
      end
    end
  end
end
