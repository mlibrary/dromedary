# Fix for Rails 5.2 bug: RoutesProxy#merge_script_names crashes when
# previous_script_name is an empty string (truthy in Ruby but has no slashes).
#
# Root cause: in rack_test / test environments, request.script_name is "" (empty),
# which overrides default_url_options[:script_name]. But the script_namer lambda
# still calls blacklight_path with the full default_url_options (which includes
# the configured script_name), generating a new_script_name with N slashes.
# With previous="" (0 slashes) and new="/m/middle-english-dictionary/" (3 slashes):
#   context_parts = 0 - 3 + 1 = -2
#   [].slice(0, -2) => nil  (Array#slice returns nil for negative length)
#   nil.join("/")   => NoMethodError
#
# Fix: treat empty previous_script_name the same as nil.
Rails.application.config.after_initialize do
  module MergeScriptNamesEmptyStringFix
    def merge_script_names(previous_script_name, new_script_name)
      return new_script_name if previous_script_name.nil? || previous_script_name.empty?
      super
    end
  end
  ActionDispatch::Routing::RoutesProxy.prepend(MergeScriptNamesEmptyStringFix)
end
