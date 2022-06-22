# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'
require_relative 'app/jobs/index_data_job'

Rails.application.load_tasks

desc 'Check for updated data file'
task :check_data do
  Yabeda.configure do
    group :check_data do
      gauge :duration_seconds, comment: "Time spent running check_data"
      gauge :last_success, comment: "Last successful run of check_data"
      gauge :last_failure, tags: :err_msg, comment: "Last failed run of check_data"
    end
  end

  START_TIME = Time.now
  Yabeda.configure!

  UPDATE_WINDOW_SECONDS = 7*24*60*60 # should update once weekly
  begin
    # puts ENV["DATA_FILE"]
    last_modified = File.mtime(ENV["DATA_FILE"])
    if (Time.now - last_modified) < UPDATE_WINDOW_SECONDS
      Yabeda.check_data.duration_seconds.set({}, Time.now - START_TIME)
      Yabeda.check_data.last_success.set({}, Time.now.to_i)
      Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
      Dromedary::IndexDataJob.perform_later(ENV["DATA_FILE"])
    end
  rescue => e
    Yabeda.check_data.last_failure.set({err_msg: e}, Time.now.to_i)
    Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
  end
end

desc 'add indexing job to sidekiq queue'
task :queue_indexing do
  Dromedary::IndexDataJob.perform_later(ENV["DATA_FILE"])
end

desc 'do indexing job now'
task :perform_indexing do
  Dromedary::IndexDataJob.perform_now(ENV["DATA_FILE"])
end