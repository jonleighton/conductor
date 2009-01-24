class Conductor::Associations::HasMany::Builder
  attr_reader :conductor_class, :name, :options, :instance
  
  def initialize(conductor_class, name, options = {})
    @conductor_class, @name, @options = conductor_class, name.to_s, options.symbolize_keys!
  end
  
  def build
    builder  = self
    
    conductor_class.class_eval do
      define_method(builder.getter_name) do
        builder.instance.records
      end
      
      define_method(builder.setter_name) do |params|
        builder.instance.parse(params)
      end
      
      define_method(builder.ids_getter_name) do
        builder.instance.ids
      end
      
      define_method(builder.ids_setter_name) do |ids|
        builder.instance.ids = ids
      end
    end
  end
  
  def instantiate_instance(conductor)
    @instance = Conductor::Associations::HasMany.new(conductor, name, options)
  end
  
  alias_method :getter_name, :name
  
  def setter_name
    "#{getter_name}="
  end
  
  def ids_getter_name
    "#{name.singularize}_ids"
  end
  
  def ids_setter_name
    "#{ids_getter_name}="
  end
end
