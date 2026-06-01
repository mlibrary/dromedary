require "hanami/cli"
require "annoying_utilities"
require_relative "logger"

module MedInstaller
# Hanami CLI commands for toggling maintenance mode.
# Maintenance mode redirects all pages to a temporary "down" page by
# creating/removing a flag file at {AnnoyingUtilities#maintenance_mode_flag_file}.
class Control
    extend MedInstaller::Logger

    class MaintenanceModeOn < Hanami::CLI::Command
      desc "Turn on maintenance mode (redirect all pages to temp down page)"

      # Creates the maintenance mode flag file, enabling maintenance mode.
      # @return [void]
      def call(command)
        File.open AnnoyingUtilities.maintenance_mode_flag_file, "w:utf-8" do |f|
          f.puts "To take out of maintenance mode, remove this file manually
                or by running `bin/dromedary maintenance_mode off`"
        end
      end
    end

    class MaintenanceModeOff < Hanami::CLI::Command
      desc "Turn off maintenance mode (redirect all pages to temp down page)"

      # Removes the maintenance mode flag file, disabling maintenance mode.
      # @return [void]
      def call(command)
        FileUtils.remove_file(AnnoyingUtilities.maintenance_mode_flag_file, :force)
      end
    end
  end
end
