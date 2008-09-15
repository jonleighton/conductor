require File.dirname(__FILE__) + '/../spec_helper'
require 'ostruct'

class DummyActiveRecord < OpenStruct
  def attributes=(params)
    params.each_pair do |key, value|
      send("#{key}=", value)
    end
  end
end

class DummyAssociationCollection < Array
  def build(params = {})
    DummyActiveRecord.new(params)
  end
  
  def delete(*items)
    items.each { |item| super(item) }
  end
end

module SpecHelpers
  def stub_updater(name, conducted_records = [], options = {})
    @conducted = DummyAssociationCollection.new(conducted_records)
    @resource = stub_everything(name => @conducted, :class => stub_everything)
    @conductor = stub_everything(:resource => @resource)
    Conductor::Updater.new(@conductor, name, options)
  end
end

module Conductor
  describe Updater, "when initialized and run, with a name of 'tables', with the option :require_attribute => :table_id" do
    include SpecHelpers
    
    before do
      @updater = stub_updater(:tables, [stub, stub], :require_attribute => :table_id)
      @updater.run(1 => { "foo" => :bar, "table_id" => 4 }, 2 => { "hoo" => :haa }, 3 => { "bla" => :yar, "table_id" => 91 }, 4 => { "table_id" => "0" })
    end
    
    it "should have an array of hashes with stringified keys as the params, and items without the id attribute deleted" do
      @updater.params.should == [{"foo" => :bar, "table_id" => 4}, { "bla" => :yar, "table_id" => 91 }]
    end
    
    it "should allow the conductor to be accessed as an attribute" do
      @updater.conductor.should == @conductor
    end
    
    it "should store the original records as a clone of the conducted item" do
      original = @resource.tables.clone
      @resource.tables << "lll"
      @updater.original_records.should == original
    end
    
    it "should allow the resource to be accessed as an attribute" do
      @updater.resource.should == @resource
    end
    
    it "should have a name of 'tables'" do
      @updater.name.should == "tables"
    end
    
    it "should return the reflection from the resource's class of the 'tables' association, when asked for the reflection" do
      @resource.class.stubs(:reflect_on_association).with(:tables).returns(reflection = stub)
      @updater.reflection.should == reflection
    end
    
    it "should set, on all records where it is nil, the primary_key_name specified by the reflection to the resource's id, " +
       "when asked to set the foreign keys" do
      @updater.stubs(:reflection).returns(stub(:primary_key_name => "foo_id"))
      @updater.stubs(:records).returns(records = [stub(:foo_id => 60), stub(:foo_id => nil), stub(:foo_id => nil)])
      @resource.stubs(:id).returns(60)
      records[1].expects(:foo_id=).with(60)
      records[2].expects(:foo_id=).with(60)
      @updater.set_foreign_keys
    end
  end
  
  describe Updater, "when initialized and run with params to update 1 item, delete 2 and add 1, " + 
                    "with a name of 'memberships', and the option 'require_attribute' => :membership_id" do
    include SpecHelpers
    
    before do
      @updater = stub_updater(:memberships, [
        OpenStruct.new("membership_id" => 6), # To be deleted
        OpenStruct.new("membership_id" => 2), # To be updated
        OpenStruct.new("membership_id" => 9)  # To be deleted
      ], 'require_attribute' => :membership_id)
      
      @updater.run(
        1 => { "membership_id" => 2 }, # Updated
        2 => { "membership_id" => 7 }  # Added
      )
    end
    
    it "should have a list of deleted records" do
      @updater.deleted_records.should == [@conducted[0], @conducted[2]]
    end
    
    it "should have a list of updated records, containing exactly the same objects from the original list of records" do
      @updater.updated_records.should have(1).item
      @updater.updated_records[0].should equal(@conducted[1])
    end
    
    it "should have a list of new records containing objects build from the params" do
      @updater.new_records.should have(1).item
      @updater.new_records[0].membership_id.should == 7
    end
    
    it "should have a list of records equal to the updated records plus the new records" do
      @updater.records.should == @updater.updated_records + @updater.new_records
    end
    
    it "should delete all the deleted records when asked to save!" do
      @resource.memberships.expects(:delete).with(@conducted[0], @conducted[2])
      @updater.save!
    end
    
    it "should save! all the records when asked to save!" do
      @updater.records.each { |record| record.expects(:save!) }
      @updater.save!
    end
  end
  
  describe Updater, "when initialized by not yet run" do
    include SpecHelpers
  
    before do
      @updater = stub_updater(:chairs)
    end
    
    it "should not be changed" do
      @updater.should_not be_changed
    end
    
    it "should return the conducted object when asked for the records" do
      @updater.records.should == @conducted
    end
  end
  
  describe Updater, "when initialized and run" do
    include SpecHelpers
    
    before do
      @updater = stub_updater(:foo)
      @updater.run({})
    end
    
    it "should be changed" do
      @updater.should be_changed
    end
  end
  
  describe Updater, "with some records" do
    include SpecHelpers
  
    before do
      @updater = stub_updater(:foo)
      @records = [OpenStruct.new(:id => 3), OpenStruct.new(:id => 7), OpenStruct.new(:id => 2)]
      @updater.stubs(:records).returns(@records)
    end
    
    it "should return a new array, using its own copies of the records where possible, when asked to merge into a superset of the records" do
      @superset = [OpenStruct.new(:id => 15), OpenStruct.new(:id => 56), OpenStruct.new(:id => 3),
                   OpenStruct.new(:id => 7),  OpenStruct.new(:id => 64), OpenStruct.new(:id => 2)]
      merged = @updater.merge_into(@superset)
      
      merged.should have(6).items
      merged[0].should equal(@superset[0])
      merged[1].should equal(@superset[1])
      merged[2].should equal(@records[0])
      merged[3].should equal(@records[1])
      merged[4].should equal(@superset[4])
      merged[5].should equal(@records[2])
    end
  end
end
