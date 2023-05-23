class AddDataToCorpusUpdates < ActiveRecord::Migration[5.2]
  def change
    add_column :corpus_updates, :corpus_data, :text
  end
end
