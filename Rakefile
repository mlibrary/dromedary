# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'
require_relative 'app/jobs/job_index'
require_relative 'lib/med_installer/job_monitoring'

Rails.application.load_tasks

desc 'sanity-check sidekiq'
task :poke_sidekiq do
  Dromedary::PokeSidekiqJob.perform_async
end

desc 'Check for updated data file'
task :check_data do
  # metrics = MiddleEnglishIndexMetrics.new({type: "check_data"})

  UPDATE_WINDOW_SECONDS = 7*24*60*60 # should update once weekly
  begin
    puts ENV["DATA_FILE"]
    last_modified = File.mtime(ENV["DATA_FILE"])
    puts last_modified
    if (Time.now - last_modified) < UPDATE_WINDOW_SECONDS
      # metrics.log_success
      puts "kicking off data job"
      Dromedary::IndexDataJob.perform_async (ENV["DATA_FILE"])
    end
  rescue => e
    # metrics.log_error(e)
  end
end

desc 'add indexing job to sidekiq queue'
task :queue_indexing do
  Dromedary::IndexDataJob.perform_async(ENV["DATA_FILE"])
end

desc 'do indexing job now'
task :perform_indexing do
  Dromedary::IndexDataJob.perform(ENV["DATA_FILE"])
end