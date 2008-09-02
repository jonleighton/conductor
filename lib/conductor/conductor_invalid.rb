module Conductor
  class ConductorInvalid < Exception
    attr_accessor :conductor
    
    def initialize(conductor)
      @conductor = conductor
    end
    
    def record
      conductor.resource
    end
  end
end
