require "sidekiq"

module Dromedary
  class PokeSidekiqJob
    include Sidekiq::Job

    def perform
      puts "hiiiiii"
    end
  end
end
