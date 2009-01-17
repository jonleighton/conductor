module Conductor
  class ConductorInvalid < StandardError
    attr_accessor :conductor
    
    def initialize(conductor)
      @conductor = conductor
    end
    
    def record
      conductor.resource
    end
  end
end
