class Conductor::Associations::HasMany
  require "conductor/associations/has_many_builder"
  
  attr_reader :conductor, :name, :parameters, :original_records, :options
  
  def initialize(conductor, name, options = {})
    @conductor        = conductor
    @name             = name.to_s
    @options          = options.symbolize_keys!
    @original_records = proxy.to_a
  end
  
  delegate :primary_key_name, :to => :reflection
  
  def base_record
    conductor.record
  end
  
  def proxy
    base_record && base_record.send(name)
  end
  
  def reflection
    @reflection ||= base_record.class.reflect_on_association(name.to_sym)
  end
  
  def records_changed?
    @records_changed == true
  end
  
  def ids_changed?
    @ids_changed == true
  end
  
  def changed?
    records_changed? || ids_changed?
  end
  
  def save!
    if records_changed?
      proxy.delete(*deleted_records)
      records.each(&:save!)
    elsif ids_changed?
      base_record.send("#{ids_name}=", ids)
    end
  end
  
  def parse(parameters)
    @parameters = parameters.values # The keys only serve to group fields in the request, so we can drop them at this point
    remove_null_parameters
    
    @parameters.each do |record_parameters|
      record_parameters.symbolize_keys!
      
      if record_parameters[:id].blank?
        build_record(record_parameters)
      else
        update_record(record_parameters)
      end
    end
    
    @records_changed = true
    @parameters
  end
  
  def records
    if records_changed?
      updated_records + new_records
    else
      original_records
    end
  end
  
  def new_records
    @new_records ||= []
  end
  
  def updated_records
    @updated_records ||= []
  end
  
  def deleted_records
    original_records.reject { |record| records.include?(record) }
  end
  
  def ids=(new_ids)
    @ids_changed = true
    @ids = new_ids.map(&:to_i)
  end
  
  def ids
    if ids_changed?
      @ids
    else
      original_records.map(&:id)
    end
  end
  
  def find(id)
    records.find { |record| record.id == id }
  end
  
  def required_key
    options[:require] && options[:require].to_sym
  end
  
  def has_key_requirement?
    !required_key.nil?
  end
  
  # Called from Conductor::Base#save! This is necessary because when the base_record is a new record
  # the foreign key won't be automatically assigned in build_record.
  def set_foreign_keys
    if records_changed?
      records.each do |record|
        record.send("#{primary_key_name}=", base_record.id)
      end
    end
  end
  
  private
    
    def build_record(parameters)
      record = proxy.build(parameters)
      record.attributes = parameters
      new_records << record
    end
    
    def update_record(parameters)
      record = find(parameters[:id].to_i)
      
      unless record.nil?
        record.attributes = parameters
        updated_records << record
      end
    end
    
    # Parameters are considered 'null' if the key (optionally) specified by the :require option
    # is blank
    def remove_null_parameters
      if has_key_requirement?
        parameters.delete_if do |record_parameters|
          record_parameters[required_key].blank?
        end
      end
    end
    
    def ids_name
      "#{name.singularize}_ids"
    end
end
