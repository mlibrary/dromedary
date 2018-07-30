require 'hanami/cli'
require 'annoying_utilities'
require_relative "logger"

module MedInstaller
  class Control
    extend MedInstaller::Logger

    class MaintenanceModeOn < Hanami::CLI::Command
      desc "Turn on maintenance mode (redirect all pages to temp down page)"

      def call(command)
        File.open AnnoyingUtilities.maintenance_mode_flag_file, 'w:utf-8' do |f|
          f.puts "To take out of maintenance mode, remove this file manually
                or by running `bin/dromedary maintenance_mode off`"
        end
      end
    end

    class MaintenanceModeOff < Hanami::CLI::Command
      desc "Turn off maintenance mode (redirect all pages to temp down page)"

      def call(command)
        FileUtils.remove_file(AnnoyingUtilities.maintenance_mode_flag_file, :force)
      end
    end
  end
end



