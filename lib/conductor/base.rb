require "active_support/callbacks"
require "conductor/associations/has_many"

class Conductor::Base
  class << self
    def associations
      @associations ||= []
    end
    
    def has_many(name, options = {})
      association = Conductor::Associations::HasMany::Builder.new(self, name, options)
      association.build
      associations << association
    end
    
    def method_missing(method_name, *args)
      if resource_class.respond_to?(method_name)
        resource_class.send(method_name, *args)
      else
        raise NoMethodError.new("undefined method `#{method_name}' for #{self}", method_name, *args)
      end
    end
    
    private
    
      def resource_class
        self.name.sub(/Conductor$/, "").constantize
      end
  end
  
  attr_reader :resource, :associations
  
  delegate :id, :to => :resource
  delegate :connection, :to => "resource.class"
  
  def initialize(resource)
    @resource = resource
    @associations = self.class.associations.map { |association| association.instantiate_instance(self) }
  end
  
  include ActiveSupport::Callbacks
  define_callbacks :before_save, :after_save
  
  # * Everything happens in a transaction so it can all be rolled back
  #   if something fails.
  # * In general, we save the updaters before the main record because the
  #   main record may have validations relating to the associations conducted
  #   by the updaters
  # * If we are dealing with a new record, we prefetch an id from the database.
  #   This allows the associations to be saved, with the correct foreign key,
  #   before the main record has actually been created, which allows validations
  #   to work which might not otherwise work. (For instance, if the main record
  #   requires that at all times there is at least one record in a has_many 
  #   association.)
  # * If the associated records' table has a foreign key constraint, it should
  #   be deferrable. It will be satisfied by the end of the transaction, but
  #   not when the association is initially saved.
  def save
    resource.class.transaction do
      run_callbacks(:before_save)
      
      if resource.new_record?
        defer_constraints
        resource.id = next_id
        associations.each(&:set_foreign_keys)
      end
      
      associations.each(&:save!)
      resource.save!
      
      run_callbacks(:after_save)
    end
    true
  rescue ActiveRecord::RecordInvalid
    resource.id = nil if resource.new_record?
    associations.each do |association|
      association.records.each(&:valid?)
    end
    resource.valid?
    false
  end
  
  def save!
    save || raise(Conductor::ConductorInvalid.new(self))
  end
  
  # Iterate each of the attributes, if there is a setter defined on this updater
  # for it then use that, then just mass assign the rest to the resource
  def attributes=(params)
    params = params.nil? ? {} : params.clone
    params.each do |attribute, value|
      if respond_to?("#{attribute}=")
        send("#{attribute}=", value) 
        params.delete(attribute)
      end
    end
    resource.attributes = params
  end
  
  def update_attributes(params)
    self.attributes = params
    save
  end
  
  def update_attributes!(params)
    update_attributes(params) || raise(Conductor::ConductorInvalid.new(self))
  end
  
  # Go through each of the records belonging to each of the updaters and
  # add their errors to the base errors object
  def errors
    unless @errors
      @errors = resource.errors.dup
      associations.each do |association|
        association.records.each do |record|
          record.errors.each_full do |message|
            @errors.add_to_base message
          end
        end
      end
    end
    @errors
  end
  
  def method_missing(method_name, *args)
    if resource.respond_to?(method_name)
      resource.send(method_name, *args)
    else
      raise NoMethodError.new("undefined method `#{method_name}' for #{self}", method_name, *args)
    end
  end
  
  private
  
    def defer_constraints
      connection.execute "SET CONSTRAINTS ALL DEFERRED;"
    end
    
    def next_id
      connection.select_rows("SELECT nextval('#{resource.class.sequence_name}');")[0][0].to_i
    end
end
