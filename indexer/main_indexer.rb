require 'middle_english_dictionary'
require_relative '../lib/annoying_utilities'
require_relative '../lib/med_installer'

settings do
  provide "log.batch_progress", 5_000
  provide 'med.data_dir', Pathname(__dir__).parent.parent + 'data'
  provide 'med.letters', '[A-Z]'
  provide 'med.letters', 'A'
  provide "reader_class_name", 'MedInstaller::Traject::EntryJsonReader'
end

to_field 'id' do |rec, acc|
  acc << rec.id
end


