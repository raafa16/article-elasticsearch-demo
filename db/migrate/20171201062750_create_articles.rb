class CreateArticles < ActiveRecord::Migration[5.1]
  def change
    create_table :articles do |t|
      t.string :title, null: false, index: true
      t.string :subtitle
      t.text :content

      t.timestamps
    end
  end
end
