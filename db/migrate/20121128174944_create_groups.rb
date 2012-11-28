class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.string :genre
      t.string :foundationYear
      t.string :endYear
      t.string :bio
      t.string :lastfmUrl

      t.timestamps
    end
  end
end
