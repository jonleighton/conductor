class Conductor::Associations::HasMany::Builder
  attr_reader :conductor_class, :name, :options, :instance
  
  def initialize(conductor_class, name, options = {})
    @conductor_class, @name, @options = conductor_class, name.to_s, options.symbolize_keys!
  end
  
  def build
    build_getter
    build_setter
  end
  
  def instantiate_instance(conductor)
    @instance = Conductor::Associations::HasMany.new(conductor, name, options)
  end
  
  alias_method :getter_name, :name
  
  def setter_name
    "#{name}="
  end
  
  private
  
    def build_getter
      builder = self
      conductor_class.class_eval do
        define_method(builder.getter_name) do
          builder.instance.records
        end
      end
    end
    
    def build_setter
      builder = self
      conductor_class.class_eval do
        define_method(builder.setter_name) do |params|
          builder.instance.parse(params)
        end
      end
    end
end
