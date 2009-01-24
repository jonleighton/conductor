class AddTags < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name, :null => false
    end
    
    create_table :books_tags, :id => false do |t|
      t.integer :book_id
      t.integer :tag_id
    end
    
    ["ruby", "rails", "python", "java", "designpatterns"].each do |tag|
      Tag.create!(:name => tag)
    end
  end

  def self.down
    drop_table :tags
  end
end
