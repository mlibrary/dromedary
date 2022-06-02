# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

desc 'Check for updated data file'
task :check_data do
  Yabeda.configure do
    group :check_data do
      gauge :check_data_duration_seconds, comment: "Time spent running check_data"
      gauge :check_data_last_success, comment: "Last successful run of check_data"
    end
  end

  START_TIME = Time.now
  Yabeda.configure!

  UPDATE_WINDOW_SECONDS = 7*24*60*60 # should update once weekly
  last_modified = File.mtime(ENV["DATA_FILE"])
  if (Time.now - last_modified) < UPDATE_WINDOW_SECONDS
    Yabeda.check_data.check_data_duration_seconds.set({}, Time.now - START_TIME)
    Yabeda.check_data.check_data_last_success.set({}, Time.now.to_i)
    Yabeda::Prometheus.push_gateway.add(Yabeda::Prometheus.registry)
  end
end