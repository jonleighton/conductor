require "active_support/callbacks"
require "conductor/conductor_invalid"

module Conductor::Associations # :nodoc:
  class HasMany # :nodoc:
  end
  require "conductor/associations/has_many"
end

class Conductor::Base
  class << self
    # Declare that we would like to manage a one-to-many association. Example:
    # 
    #   class Person < ActiveRecord::Base
    #     has_many :possessions
    #   end
    # 
    #   class PersonConductor < Conductor::Base
    #     has_many :possessions
    #   end
    def has_many(name, options = {})
      association = Conductor::Associations::HasMany::Builder.new(self, name, options)
      association.build
      associations << association
    end
    
    def associations # :nodoc:
      @associations ||= []
    end
    
    def method_missing(method_name, *args) # :nodoc:
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
  
  # The record should be the ActiveRecord::Base instance that we are conducting.
  def initialize(record)
    @record = record
    @associations = self.class.associations.map { |association| association.instantiate_instance(self) }
  end
  
  include ActiveSupport::Callbacks
  define_callbacks :before_save, :after_save
  
  # Everything in the save happens in a transaction. All the associated records which we are managing
  # are saved, and then the record itself is saved. If at any point a save fails then all changes
  # are rolled back.
  #
  # A return value of true indicates success, and false indicates failure.
  #
  # Callbacks can be registered in the same way as on ActiveRecord::Base object. The available
  # callbacks are +before_save+ and +after_save+. These also happen within the transaction.
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
  
  # Calls save, but raises a Conductor::ConductorInvalid if it fails
  def save!
    save || raise(Conductor::ConductorInvalid.new(self))
  end
  
  # Assigns the given hash of attributes to this conductor. Attributes which the conductor
  # doesn't know how to deal with are passed to the underlying record.
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
  
  # Assign the given attributes and then try to save
  def update_attributes(params)
    self.attributes = params
    save
  end
  
  # Calls update_attributes but raises a Conductor::ConductorInvalid if it fails
  def update_attributes!(params)
    update_attributes(params) || raise(Conductor::ConductorInvalid.new(self))
  end
  
  # An aggregation of all errors from the conducted record and all associated record which we
  # are managing.
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
  
  def association_records # :nodoc:
    associations.map(&:records).flatten
  end
  
  def record_name # :nodoc:
    ActionController::RecordIdentifier.singular_class_name(record)
  end
  
  def method_missing(method_name, *args) # :nodoc:
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
