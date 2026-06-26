require "prometheus/client"
require "prometheus/client/push"
require "prometheus/client/registry"

# Pushes indexing job metrics to a Prometheus Pushgateway.
#
# Records job duration, last-success timestamp, errors, and warnings as
# Prometheus gauges.  Metrics are pushed via +PROMETHEUS_PUSH_GATEWAY+
# (read from ENV at runtime).
class MiddleEnglishIndexMetrics
  # @param labels [Hash] grouping-key labels for this job instance (e.g. +{type: "full_index"}+)
  def initialize(labels)
    @labels = labels
    @start_time = current_timestamp
  end

  # Records job duration and last-success timestamp, then pushes to the gateway.
  # @return [void]
  def log_success
    indexing_job_duration_seconds.set(current_timestamp - @start_time)
    indexing_job_last_success.set(current_timestamp)
    gateway.add(registry)
  end

  # Records an error gauge and pushes to the gateway.
  # @param err [String] error message used as the +err_msg+ label
  # @return [void]
  def log_error(err)
    indexing_job_error.set(current_timestamp, labels: {err_msg: err})
    gateway.add(registry)
  end

  # Records a warning gauge and pushes to the gateway.
  # @param warn [String] warning message used as the +warning+ label
  # @return [void]
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
