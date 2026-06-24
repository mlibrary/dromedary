module MiddleEnglishDictionary
  # Normalize a raw MED entry ID by stripping leading zeros after the "MED" prefix.
  #
  # @example
  #   MiddleEnglishDictionary.normalize_med_id("MED003366") #=> "MED3366"
  #
  # @param medid [String] raw MED identifier, e.g. "MED003366"
  # @return [String] normalized identifier, e.g. "MED3366"
  def self.normalize_med_id(medid)
    medid.gsub(/MED0+/, "MED")
  end
end
