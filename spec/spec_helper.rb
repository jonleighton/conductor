%w(rubygems spec active_support ostruct).each { |r| require r }
require File.dirname(__FILE__) + "/../init"

Spec::Runner.configure do |config|
  config.mock_with :mocha
end


class DummyActiveRecord < OpenStruct
  # Otherwise OpenStruct defers to Object#id. It really ought to intercept *every* method.
  def id
    @table[:id] || super
  end
  
  def attributes=(params)
    params.each_pair do |key, value|
      send("#{key}=", value)
    end
  end
end

class DummyAssociationProxy < Array
  def build(params = {})
    DummyActiveRecord.new(params)
  end
  
  def delete(*items)
    items.each { |item| super(item) }
  end
end

# Fake it, as the real version isn't needed
module ActionController
  module RecordIdentifier
  end
end
