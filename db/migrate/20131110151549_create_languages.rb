class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.string :name

      t.timestamps
    end
    create_table :languages_users, :id => false do |t|
      t.belongs_to :user
      t.belongs_to :language
    end
  end
end
