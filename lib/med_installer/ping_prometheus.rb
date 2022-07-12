require_relative '../../config/load_local_config'

module MedInstaller

  class PingPrometheus < Hanami::CLI::Command

    class YabedaHelper
        attr_accessor :start_time, :enabled
        def initialize
            @enabled = false
            if ENV['PROMETHEUS_PUSH_GATEWAY']
                         @enabled = true
                       end
            puts "enabled: #{@enabled}"
          end
        def say_hi
            puts "hi from yabeda helper. enabled status: #{@enabled}"
          end
      end

    def call(_)
      puts "hi!"
    end
  end
end