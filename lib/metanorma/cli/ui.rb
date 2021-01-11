require "thor"

module Metanorma
  module Cli
    class UI < Thor
      def self.ask(message, options = {})
        new.ask(message, options)
      end

      def self.say(message)
        new.say(message)
      end

      def self.info(message)
        new.say(["[info]", message].join(": "))
      end

      def self.error(message)
        new.error(message)
      end

      def self.table(header, data)
        new.print_table(data.unshift(header))
      end

      def self.run(command)
        require "open3"
        Open3.capture3(command)
      end
    end
  end
end
