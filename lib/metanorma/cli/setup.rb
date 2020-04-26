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
        Fontist::Finder.find(font_name)
      rescue Fontist::Errors::MissingFontError
        ask_user_and_download_font(font_name)
      end

      def copy_to_fonts(fonts_path)
        fonts_path.each do |font_path|
          font_name = File.basename(font_path)
          FileUtils.copy_file(font_path, metanorma_fonts_path.join(font_name))
        end
      end

      def ask_user_and_download_font(font_name)
        response = term_agreement ? "yes" : "no"

        if !term_agreement
          response = UI.ask(message.strip)
        end

        if response.downcase === "yes"
          Fontist::Installer.download(font_name, confirmation: response)
        end
      end

      def message
        <<~MSG
        Metanorma has detected that you do not have the necessary fonts installed
        for PDF generation. The generated PDF will use generic fonts that may not
        resemble the desired styling. Metanorma can download these files for you
        if you accept the font licensing conditions for the font #{font_name}.

        If you want Metanorma to download these fonts for you and indicate your
        acceptance of the font licenses, type "Yes" / "No":
        MSG
      end
    end
  end
end
