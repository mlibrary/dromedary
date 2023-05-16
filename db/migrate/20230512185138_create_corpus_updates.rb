class CreateCorpusUpdates < ActiveRecord::Migration[5.2]
  def change
    create_table :corpus_updates do |t|
      t.string :status

      t.timestamps
    end
  end
end
