module Metanorma
  module Cli
    class Collection
      # @parma options [Hash]
      # @option options [String] :filename path to collection
      # @option options [Array<String>] :format list of formats
      # @option options [String] :output_folder
      # @option options [String] :coverpage path to template file
      # def initialize(options)
      #   @options = options
      # end

      # @param filename [String] path to collection
      # @parma options [Hash]
      # @option options [String] :format comma-delimited list of formats
      # @option options [String] :"output-folder"
      # @option options [String] :coverpage path to template file
      # @return [String] XML collection
      def self.generate(filename, options)
        if options[:format]
          options[:format] = options[:format].split(",").map &:to_sym
        end
        options[:output_folder] = options.delete :"output-folder"
        xml = File.read filename, encoding: "UTF-8"
        folder = File.dirname(filename)
        Metanorma::CollectionRenderer.render(xml, folder, options)
      rescue Nokogiri::XML::XPath::SyntaxError
        xml = Metanorma::Yaml2XmlCollection.convert filename
        Metanorma::CollectionRenderer.render(xml, folder, options)
      rescue ArgumentError => e
        UI.say e.message
      end

      # @return [String] XML collection
      # def generate
      #   xml = Metanorma::Yaml2XmlCollection.convert @options[:filename]
      #   Metanorma::CollectionRenderer.render xml, **@options
      # rescue ArgumentError => e
      #   UI.say e.message
      # end
    end
  end
end