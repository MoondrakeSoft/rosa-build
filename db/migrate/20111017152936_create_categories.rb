class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name
      t.string :ancestry
      t.integer :projects_count, default: 0, null: false

      t.timestamps
    end
  end

  def self.down
    drop_table :categories
  end
end
