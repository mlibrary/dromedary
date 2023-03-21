require_relative "job_monitoring"

require "fileutils"

require_relative "../../config/load_local_config"
module MedInstaller
  class PingPrometheus < Hanami::CLI::Command
    def call(_)
      puts "hi!"
      metrics = MiddleEnglishIndexMetrics.new({type: "ping"})
      metrics.log_success
    end
  end
end
