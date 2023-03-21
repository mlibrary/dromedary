require "prometheus/client"
require "prometheus/client/push"
require "prometheus/client/registry"

class MiddleEnglishIndexMetrics
  def initialize(labels)
    @labels = labels
    @start_time = current_timestamp
  end

  def log_success
    indexing_job_duration_seconds.set(current_timestamp - @start_time)
    indexing_job_last_success.set(current_timestamp)
    gateway.add(registry)
  end

  def log_error(err)
    indexing_job_error.set(current_timestamp, labels: {err_msg: err})
    gateway.add(registry)
  end

  def log_warning(warn)
    indexing_job_warning.set(current_timestamp, labels: {warning: warn})
    gateway.add(registry)
  end

  private

  def current_timestamp
    Time.now.to_i
  end

  def registry
    @registry ||= Prometheus::Client::Registry.new
  end

  def gateway
    @gateway ||= Prometheus::Client::Push.new(
      job: "middle_english_index",
      gateway: ENV["PROMETHEUS_PUSH_GATEWAY"],
      grouping_key: @labels
    )
  end

  def indexing_job_last_success
    @indexing_job_last_success ||= registry.gauge(
      :indexing_job_last_success,
      docstring: "Last successful run of an indexing job"
    )
  end

  def indexing_job_duration_seconds
    @indexing_job_duration_seconds ||= registry.gauge(
      :indexing_job_duration_seconds,
      docstring: "Time spent running an indexing job"
    )
  end

  def indexing_job_error
    @indexing_job_error ||= registry.gauge(
      :indexing_job_error,
      docstring: "An error occurred during indexing!"
    )
  end

  def indexing_job_warning
    @indexing_job_warning ||= registry.gauge(
      :indexing_job_warning,
      docstring: "A warning occurred during indexing"
    )
  end
end
