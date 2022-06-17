require 'pry-byebug'

module Dromedary
  class IndexDataJob < ActiveJob::Base

    queue_as :default

    def perform(filename)
      puts "performing index data job"
      exit_code = %x( bin/dromedary newdata prepare #{filename} )
      puts "finished preparing with exit code #{exit_code}"
      if exit_code == "0"
        exit_code = %x( bin/dromedary newdata index )
        puts "finished indexing with exit code #{exit_code}"
      end
    end
  end
end
