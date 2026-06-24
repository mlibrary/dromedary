module MiddleEnglishDictionary
  # Raised when a requested file does not exist on disk.
  class FileNotFound < RuntimeError; end

  # Raised when a file exists but contains no data.
  class FileEmpty < RuntimeError; end

  # Raised when XML content cannot be parsed (malformed or invalid structure).
  class InvalidXML < RuntimeError; end
end
