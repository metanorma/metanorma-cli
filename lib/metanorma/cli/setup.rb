require "fontist"
require "fileutils"

module Metanorma
  module Cli
    class Setup
      def initialize(options)
        @options = options
        @font_name = options.fetch(:font)
        @term_agreement = options.fetch(:term_agreement, false)

        create_metanorma_fonts_directory
      end

      def self.run(options = {})
        new(options).run
      end

      def run
        font = Metanorma::Cli.fonts.grep(/#{font_name}/i)

        if font.empty?
          font_paths = download_font
          copy_to_fonts(font_paths)
        end
      end

      private

      attr_reader :font_name, :options, :term_agreement

      def create_metanorma_fonts_directory
        unless Metanorma::Cli.fonts_directory.exist?
          FileUtils.mkdir_p(Metanorma::Cli.fonts_directory)
        end
      end

      def metanorma_fonts_path
        @metanorma_fonts_path ||= Metanorma::Cli.fonts_directory
      end

      def download_font
        begin
          Fontist::Font.find(font_name)
        rescue Fontist::Errors::MissingFontError
          process_font_installation(font_name)
        end
      end

      def copy_to_fonts(fonts_path)
        fonts_path.each do |font_path|
          font_name = File.basename(font_path)
          FileUtils.copy_file(font_path, metanorma_fonts_path.join(font_name))
        end
      end

      def process_font_installation(font_name)
        accepted_agreement = term_agreement == true ? "yes" : "no"

        UI.say(missing_font_message) if !term_agreement
        Fontist::Font.install(font_name, confirmation: accepted_agreement)
      end

      def missing_font_message
        <<~MSG
          Metanorma has detected that you do not have the necessary fonts installed
          for PDF generation. Without those fonts, the generated PDF will use
          generic fonts that may not resemble the desired styling.\n
        MSG
      end
    end
  end
end
