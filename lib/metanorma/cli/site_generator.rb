module Metanorma
  module Cli
    class SiteGenerator
      def initialize(source)
        @source = source
      end

      def self.generate(source)
        new(source).generate
      end

      def generate
        # 
        # Steps to generat  a document
        #
        # => figure out the steps from makefile
      end
    end
  end
end
