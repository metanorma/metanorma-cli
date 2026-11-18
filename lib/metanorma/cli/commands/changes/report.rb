# frozen_string_literal: true

require "json"
require "yaml"

module Metanorma
  module Cli
    module Commands
      class Changes
        # Renders a change report as text, YAML or JSON.
        class Report
          FORMATS = %w[text yaml json].freeze

          def initialize(data, options = {})
            @data = data
            @format = (options[:format] || "text").to_s
            @language = (options[:language] || "en").to_s
          end

          def render
            unless FORMATS.include?(@format)
              raise "unsupported format #{@format} (#{FORMATS.join(', ')})"
            end

            case @format
            when "yaml" then YAML.dump(@data)
            when "json" then JSON.pretty_generate(@data)
            else text
            end
          end

          private

          def text
            units = @data["units"]
            lines = ["Changes from #{@data['from']} to #{@data['to']}",
                     "Update units changed: #{units.size}"]
            units.each { |u| lines.concat(unit_lines(u)) }
            lines.concat(document_lines) if @data.key?("documents")
            lines.join("\n")
          end

          def unit_lines(unit)
            head = "  #{unit['unit']} (#{unit['status']}) #{unit['path']}"
            records = unit["records"]
            return [head, "    no new amendment record"] if records.empty? &&
              unit["status"] != "removed"

            [head] + records.map { |r| "    #{record_line(r)}" }
          end

          def record_line(record)
            fields = [record["anchor"], "##{record['sequence']}",
                      record["edition"], record["date"], record["reference"]]
            line = fields.compact.map(&:to_s).reject(&:empty?).join(" ")
            text = summary(record["summary"])
            text ? "#{line}: #{text}" : line
          end

          def summary(entries)
            list = Array(entries).grep(Hash)
            pick = list.find { |s| s["language"].to_s == @language } ||
              list.first
            pick && pick["content"]
          end

          def document_lines
            docs = @data["documents"]
            ["Documents to rebuild: #{docs.size}"] +
              docs.map { |d| "  #{d['file']}" }
          end
        end
      end
    end
  end
end
