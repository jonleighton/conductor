# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080902100811) do

  create_table "authors", :force => true do |t|
    t.string "name", :null => false
  end

  create_table "authorships", :force => true do |t|
    t.integer "book_id",   :null => false
    t.integer "author_id", :null => false
    t.string  "role",      :null => false
  end

  create_table "books", :force => true do |t|
    t.string  "name",         :null => false
    t.integer "publisher_id", :null => false
  end

  create_table "publishers", :force => true do |t|
    t.string "name", :null => false
  end

  add_foreign_key "authorships", ["book_id"], "books", ["id"], :deferrable => true, :name => "authorships_book_id_fkey"
  add_foreign_key "authorships", ["author_id"], "authors", ["id"], :name => "authorships_author_id_fkey"

  add_foreign_key "books", ["publisher_id"], "publishers", ["id"], :name => "books_publisher_id_fkey"

end
