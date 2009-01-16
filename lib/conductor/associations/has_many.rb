class Conductor::Associations::HasMany
  require "conductor/associations/has_many_builder"
  
  attr_reader :conductor, :name, :params, :original_records, :options
  
  def initialize(conductor, name, options = {})
    @conductor, @name, @options = conductor, name.to_s, options.symbolize_keys!
    @original_records = conducted.to_a.clone
  end
  
  delegate :resource, :to => :conductor
  delegate :primary_key_name, :to => :reflection
  
  def params=(new_params)
    # The keys only serve to group fields together, so we can drop them at this point
    new_params = new_params.values
    
    # Delete any params which don't have the required attribute
    if options[:require]
      required_attr = options[:require].to_s
      new_params.delete_if do |item_params|
        item_params[required_attr].blank? ||
        item_params[required_attr] == "0"
      end
    end
    
    @params = new_params
  end
  
  def changed?
    @changed == true
  end
  
  def save!
    conducted.delete(*deleted_records)
    records.each(&:save!)
  end
  
  def reflection
    @reflection ||= resource.class.reflect_on_association(name.to_sym)
  end
  
  # This is necessary because when the resource is a new record the foreign key won't
  # be automatically assigned in update_item. However, it should probably be invoked
  # in save!, rather than relying in the Conductor::Base to invoke it.
  def set_foreign_keys
    records.each do |record|
      if record.send(primary_key_name).nil?
        record.send("#{primary_key_name}=", resource.id)
      end
    end
  end
  
  def run(params)
    @changed = true
    self.params = params
    self.params.each { |item_params| update_item(item_params) }
  end
    
  def conducted
    resource.send(name)
  end
  
  def records
    if changed?
      updated_records + new_records
    else
      conducted
    end
  end
  
  def deleted_records
    original_records.reject { |item| records.include? item }
  end
  
  def updated_records
    @updated_records ||= []
  end
  
  def new_records
    @new_records ||= []
  end
  
  # The idea here is that other_records is a superset of whatever records
  # are handled by this updater. We want to merge in the actual records
  # held by the updater in order to preserve any changes since they were
  # initialized. (For instance, so that we can re-render the form in exactly
  # the state it was submitted in.)
  def merge_into(other_records)
    other_records.map do |other_record|
      if has_record?(other_record)
        find(other_record)
      else
        other_record
      end
    end
  end
  
  private
    
    def has_record?(record)
      !find(record).nil?
    end
    
    def find(other_record)
      records.to_a.find { |record| other_record == record }
    end
    
    def original_record?(record)
      !find_original(record).nil?
    end
    
    def find_original(record)
      original_records.to_a.find { |original_record| original_record == record }
    end
    
    def update_item(params)
      new_record = conducted.build(params)
      new_record.send("#{primary_key_name.sub(/_id$/, '')}=", resource) # FIXME: This won't work with custom primary keys
      
      if original_record?(new_record)
        # Use the record that already exists, rather than the new one We do
        # the deletion using eql? because == might delete the existing one
        conducted.delete_if { |record| record.equal?(new_record) }
        updated_record = find_original(new_record)
        updated_record.attributes = params
        
        updated_records << updated_record
      else
        new_records << new_record
      end
    end
end
