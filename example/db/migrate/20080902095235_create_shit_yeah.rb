class CreateShitYeah < ActiveRecord::Migration
  def self.up
    create_table :books do |t|
      t.string :name, :null => false
      t.integer :publisher_id, :null => false
    end
    
    create_table :publishers do |t|
      t.string :name, :null => false
    end
    
    add_foreign_key(:books, :publisher_id, :publishers, :id)
    
    create_table :authors do |t|
      t.string :name, :null => false
    end
    
    create_table :authorships do |t|
      t.integer :book_id, :null => false
      t.integer :author_id, :null => false
      t.string :role, :null => false
    end
    
    add_foreign_key(:authorships, :book_id, :books, :id, :deferrable => true)
    add_foreign_key(:authorships, :author_id, :authors, :id)
  end

  def self.down
    drop_table :authorships
    drop_table :publishers
    drop_table :authors
    drop_table :books
  end
end
