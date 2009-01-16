class ExampleData < ActiveRecord::Migration
  def self.up
    ["The Pragmatic Programmers", "O'Reilly"].each do |pub|
      Publisher.create! :name => pub
    end
    
    ["Eric Freeman", "DHH", "Kathy Sierra", "Elisabeth Freeman", "Dave Thomas"].each do |auth|
      Author.create! :name => auth
    end
  end

  def self.down
  end
end
