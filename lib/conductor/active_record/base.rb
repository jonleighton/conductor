require "active_record"

module Conductor::ActiveRecord
  require "conductor/active_record/buildable_from"
end

ActiveRecord::Base.send :extend, Conductor::ActiveRecord::BuildableFrom
