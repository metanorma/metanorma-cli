require "metanorma/cli/template_repo"

module Metanorma
  module Cli
    module Commands
      class TemplateRepo < Thor
        desc "add NAME SOURCE", "Add new metanorma templates repository"
        option :overwrite, aliases: "-y", type: :boolean, desc: "Overwrite existing template"

        def add(name, source)
          Metanorma::Cli::TemplateRepo.add(name, source, options)
          UI.say("Template repo: #{name} has been added successfully")

        rescue Errors::DuplicateTemplateError
          UI.error("Duplicate metanorma template")
        end
      end
    end
  end
end
