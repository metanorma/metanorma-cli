require "git"

module Metanorma
  module Cli
    class GitTemplate
      def initialize(name, options = {})
        @name = name
        @options = options
      end

      def remove!
        remove_template
        return true
      end

      def download
        remove!
        clone_git_template(options[:repo])

      rescue Git::GitExecuteError
        UI.say("Invalid template reoository!")
        return nil
      end

      def find_or_download
        find_template || download_template
      end

      # Find or Download
      #
      # This interface expects a name / type, and then it will
      # find that template, or if non exist then it will download
      # and return the downloaded path.
      #
      def self.find_or_download_by(name)
        new(name).find_or_download
      end

      # Download a template
      #
      # This interface expects a name, and remote repository link
      # for a template, then it will download that template and it
      # will return the downloaded path.
      #
      # By default, downloaded tempaltes will be stored in a sub
      # directoy inside metanorma's tempaltes directory, but if
      # you don't want then you can set the `remote` to false.
      #
      def self.download(name, repo:, remote: true)
        new(name, repo: repo, remote: remote).download
      end

      private

      attr_reader :name, :options

      def find_template
        if template_path.exist?
          template_path
        end
      end

      def download_template
        template_repo = git_repos[name.to_sym]

        if template_repo
          clone_git_template(template_repo)
        end
      end

      def remove_template
        if template_path.exist?
          template_path.rmtree
        end
      end

      def clone_git_template(repo)
        clone = Git.clone(repo, name, path: templates_path)
        template_path unless clone.nil?
      end

      def git_repos
        @git_repos ||= {
          csd: "https://github.com/metanorma/mn-templates-csd",
          ogc: "https://github.com/metanorma/mn-templates-ogc",
          iso: "https://github.com/metanorma/mn-templates-iso",
          iec: "https://github.com/metanorma/mn-templates-iec",
          itu: "https://github.com/metanorma/mn-templates-itu",
          ietf: "https://github.com/metanorma/mn-templates-ietf"
        }
      end

      def templates_path
        @templates_path ||= build_templates_path
      end

      def build_templates_path
        sub_directory = options[:remote] == true ? "git" : nil
        Metanorma::Cli.templates_path.join(sub_directory.to_s)
      end

      def template_path
        @template_path ||= templates_path.join(name.to_s.downcase)
      end
    end
  end
end
