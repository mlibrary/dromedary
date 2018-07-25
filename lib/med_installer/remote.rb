require 'hanami/cli'
require 'annoying_utilities'
require_relative "logger"

module MedInstaller
  class Remote
    extend MedInstaller::Logger


    class Deploy < Hanami::CLI::Command
      desc "Deploy to a valid target (testing/staging/production)"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"
      argument :branch, default: "", desc: "Which branch/tag/SHA to deploy"

      def call(target:, branch:)
        system "ssh deployhost deploy dromedary-#{target} #{branch}"
      end
    end


    class Restart < Hanami::CLI::Command
      desc "Restart the puma server for a valid target"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"

      def call(target:)
        system "ssh deployhost restart dromedary-#{target}"
      end
    end

    class Dromedary < Hanami::CLI::Command
      desc "Run a bin/dromedary command on a remote server"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"
      argument :command, required: true, desc: "The command to run (e.g., \"solr reload\" IN DOUBLE QUOTES)"

      def call(target:, command:)
        system "ssh deployhost exec --env=RAILS_ENV:production dromedary-#{target} ruby bin/dromedary #{command}"
      end
    end

    class Exec < Hanami::CLI::Command
      desc "Run an arbitrary command using deploy exec"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"
      argument :command, required: true, desc: "The command to run (e.g., \"curl http://localhost...\" IN DOUBLE QUOTES)"

      def call(target:, command:)
        system "ssh deployhost exec --env=RAILS_ENV:production dromedary-#{target} #{command}"
      end
    end

  end
end
