require "active_record"

module Conductor::ActiveRecord # :nodoc:
  require "conductor/active_record/buildable_from"
end

ActiveRecord::Base.send :extend, Conductor::ActiveRecord::BuildableFrom
