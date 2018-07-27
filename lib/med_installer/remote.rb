require 'hanami/cli'
require 'annoying_utilities'
require_relative "logger"

module MedInstaller
  class Remote
    extend MedInstaller::Logger

    VALID_TARGETS = %w[testing staging production]
    PANIC_PAUSE = 5


    def self.valid_target?(t)
      target = t.downcase
      VALID_TARGETS.include? target
    end

    def self.validate_target!(t)
      if valid_target?(t)
        t.downcase
      else
        raise "Target must be one of [#{VALID_TARGETS.join(', ')}]"
      end
    end

    class Deploy < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Deploy to a valid target (testing/staging/production)"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"
      argument :branch, default: "", desc: "Which branch/tag/SHA to deploy"

      def call(target:, branch:)
        target = Remote.validate_target!(target)
        logger.info "Deploying #{branch} to #{target.upcase}"
        sleep(Remote::PANIC_PAUSE)
        system "ssh deployhost deploy -v dromedary-#{target} #{branch}"
      end
    end


    class Restart < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Restart the puma server for a valid target"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"

      def call(target:)
        target = Remote.validate_target!(target)
        logger.info "Restarting puma server for #{target.upcase}"
        system "ssh deployhost restart dromedary-#{target}"
      end
    end

    class Dromedary < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Run a bin/dromedary command on a remote server"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"
      argument :command, required: true, desc: "The command to run (e.g., \"solr reload\" IN DOUBLE QUOTES)"

      def call(target:, command:)
        target = Remote.validate_target!(target)
        logger.info "Telling #{target.upcase} to run 'bin/dromedary #{command}'"
        sleep(Remote::PANIC_PAUSE)
        system "ssh deployhost exec -v --env=RAILS_ENV:production dromedary-#{target} ruby bin/dromedary #{command}"
      end
    end

    class Exec < Hanami::CLI::Command
      include MedInstaller::Logger

      desc "Run an arbitrary command using deploy exec"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"
      argument :command, required: true, desc: "The command to run (e.g., \"curl http://localhost...\" IN DOUBLE QUOTES)"

      def call(target:, command:)
        target = Remote.validate_target!(target)
        sleep(Remote::PANIC_PAUSE)
        system "ssh deployhost exec -v --env=RAILS_ENV:production dromedary-#{target} #{command}"
      end
    end

    class MaintenanceMode < Hanami::CLI::Command
      include MedInstaller::Logger


      MAINTENANCE_MODE_TAG = "KEEP_maintenance_mode"


      desc "Put the given remote into maintenance mode"
      argument :target, required: true, desc: "Which deployment (testing/staging/production)"

      def call(target:)
        target = Remote.validate_target!(target)
        sleep(Remote::PANIC_PAUSE)
        logger.info "Putting #{target.upcase} into maintenance mode by checking out tag '#{MAINTENANCE_MODE_TAG}'"
        system "ssh deployhost deploy -v dromedary-#{target} #{MAINTENANCE_MODE_TAG}"
      end

    end

  end
end
