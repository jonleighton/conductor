require "active_support/callbacks"
require "conductor/conductor_invalid"

module Conductor::Associations
  require "conductor/associations/has_many"
end

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
      if record_class.respond_to?(method_name)
        record_class.send(method_name, *args)
      else
        raise NoMethodError.new("undefined method `#{method_name}' for #{self}", method_name, *args)
      end
    end
    
    private
    
      def record_class
        self.name.sub(/Conductor$/, "").constantize
      end
  end
  
  extend ActiveSupport::Memoizable
  
  attr_reader :record, :associations
  
  delegate :id, :to => :record
  delegate :connection, :to => "record.class"
  
  def initialize(record)
    @record = record
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
    record.class.transaction do
      run_callbacks(:before_save)
      
      if record.new_record?
        defer_constraints
        record.id = next_id
        associations.each(&:set_foreign_keys)
      end
      
      associations.each(&:save!)
      record.save!
      
      run_callbacks(:after_save)
    end
    true
  rescue ActiveRecord::RecordInvalid
    record.id = nil if record.new_record?
    associations.each do |association|
      association.records.each(&:valid?)
    end
    record.valid?
    false
  end
  
  def save!
    save || raise(Conductor::ConductorInvalid.new(self))
  end
  
  # Iterate each of the attributes, if there is a setter defined on this updater
  # for it then use that, then just mass assign the rest to the record
  def attributes=(params)
    params = params.nil? ? {} : params.clone
    params.each do |attribute, value|
      if respond_to?("#{attribute}=")
        send("#{attribute}=", value) 
        params.delete(attribute)
      end
    end
    record.attributes = params
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
    errors = record.errors.dup
    association_records.each do |record|
      record.errors.each do |attribute, message|
        if attribute == "base"
          errors.add_to_base("#{record}: #{message}")
        else
          errors.add_to_base("The #{attribute} for #{record} #{message}")
        end
      end
    end
    errors
  end
  memoize :errors
  
  def association_records
    associations.map(&:records).flatten
  end
  
  def record_name
    ActionController::RecordIdentifier.singular_class_name(record)
  end
  
  def method_missing(method_name, *args)
    if record.respond_to?(method_name)
      record.send(method_name, *args)
    else
      raise NoMethodError.new("undefined method `#{method_name}' for #{self}", method_name, *args)
    end
  end
  
  private
  
    def defer_constraints
      connection.execute "SET CONSTRAINTS ALL DEFERRED;"
    end
    
    def next_id
      connection.select_rows("SELECT nextval('#{record.class.sequence_name}');")[0][0].to_i
    end
end
