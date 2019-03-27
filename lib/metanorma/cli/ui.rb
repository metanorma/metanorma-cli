require "thor"

module Metanorma
  module Cli
    class UI < Thor
      def self.ask(message)
        new.ask(message)
      end

      def self.say(message)
        new.say(message)
      end

      def self.run(command)
        require "open3"
        Open3.capture3(command)
      end
    end
  end
end
