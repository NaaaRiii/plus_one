class CreateRouletteTexts < ActiveRecord::Migration[7.0]
  def change
    create_table :roulette_texts do |t|
      t.integer :number
      t.string :text
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
