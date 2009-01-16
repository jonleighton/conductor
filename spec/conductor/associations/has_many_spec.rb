require File.dirname(__FILE__) + '/../../spec_helper'
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
  def stub_association(conducted_name, resource_name = :idontfuckingcare, conducted_records = [], options = {})
    @conducted = DummyAssociationCollection.new(conducted_records)
    @resource = stub_everything(conducted_name => @conducted, :class => stub_everything)
    @reflection = stub_everything(:primary_key_name => resource_name.to_s.singularize.foreign_key)
    @resource.class.stubs(:reflect_on_association).with(conducted_name).returns(@reflection)
    @conductor = stub_everything(:resource => @resource)
    Conductor::Associations::HasMany.new(@conductor, conducted_name, options)
  end
end

module Conductor::Associations
  describe HasMany, "when initialized and run, with a name of 'tables', with the option :require => :table_id" do
    include SpecHelpers
    
    before do
      @association = stub_association(:tables, :house, [stub, stub], :require => :table_id)
      @association.run(1 => { "foo" => :bar, "table_id" => 4 }, 2 => { "hoo" => :haa }, 3 => { "bla" => :yar, "table_id" => 91 }, 4 => { "table_id" => "0" })
    end
    
    it "should have an array of hashes with stringified keys as the params, and items without the id attribute deleted" do
      @association.params.should == [{"foo" => :bar, "table_id" => 4}, { "bla" => :yar, "table_id" => 91 }]
    end
    
    it "should allow the conductor to be accessed as an attribute" do
      @association.conductor.should == @conductor
    end
    
    it "should store the original records as a clone of the conducted item" do
      original = @resource.tables.clone
      @resource.tables << "lll"
      @association.original_records.should == original
    end
    
    it "should allow the resource to be accessed as an attribute" do
      @association.resource.should == @resource
    end
    
    it "should have a name of 'tables'" do
      @association.name.should == "tables"
    end
    
    it "should return the reflection from the resource's class of the 'tables' association, when asked for the reflection" do
      @association.reflection.should == @reflection
    end
    
    it "should set, on all records where it is nil, the primary_key_name specified by the reflection to the resource's id, " +
       "when asked to set the foreign keys" do
      @association.stubs(:records).returns(records = [stub(:house_id => 60), stub(:house_id => nil), stub(:house_id => nil)])
      @resource.stubs(:id).returns(60)
      records[1].expects(:house_id=).with(60)
      records[2].expects(:house_id=).with(60)
      @association.set_foreign_keys
    end
  end
  
  describe HasMany, "when initialized and run with params to update 1 item, delete 2 and add 1, " + 
                    "with a name of 'memberships', and the option 'require' => :membership_id" do
    include SpecHelpers
    
    before do
      @existing_records = [
        OpenStruct.new("membership_id" => 6), # To be deleted
        OpenStruct.new("membership_id" => 2), # To be updated
        OpenStruct.new("membership_id" => 9)  # To be deleted
      ]
      @association = stub_association(:memberships, :club, @existing_records, 'require' => :membership_id)
      @existing_records.each { |r| r.club = @resource }
      
      @association.run(
        1 => { "membership_id" => 2 }, # Updated
        2 => { "membership_id" => 7 }  # Added
      )
    end
    
    it "should have a list of deleted records" do
      @association.deleted_records.should == [@conducted[0], @conducted[2]]
    end
    
    it "should have a list of updated records, containing exactly the same objects from the original list of records" do
      @association.updated_records.should have(1).item
      @association.updated_records[0].should equal(@conducted[1])
    end
    
    it "should have a list of new records containing objects build from the params" do
      @association.new_records.should have(1).item
      @association.new_records[0].membership_id.should == 7
    end
    
    it "should assign the association to the resource on each of the new records" do
      @association.new_records[0].club.should == @resource
    end
    
    it "should have a list of records equal to the updated records plus the new records" do
      @association.records.should == @association.updated_records + @association.new_records
    end
    
    it "should delete all the deleted records when asked to save!" do
      @resource.memberships.expects(:delete).with(@conducted[0], @conducted[2])
      @association.save!
    end
    
    it "should save! all the records when asked to save!" do
      @association.records.each { |record| record.expects(:save!) }
      @association.save!
    end
  end
  
  describe HasMany, "when initialized by not yet run" do
    include SpecHelpers
  
    before do
      @association = stub_association(:chairs)
    end
    
    it "should not be changed" do
      @association.should_not be_changed
    end
    
    it "should return the conducted object when asked for the records" do
      @association.records.should == @conducted
    end
  end
  
  describe HasMany, "when initialized and run" do
    include SpecHelpers
    
    before do
      @association = stub_association(:foo)
      @association.run({})
    end
    
    it "should be changed" do
      @association.should be_changed
    end
  end
  
  describe HasMany, "with some records" do
    include SpecHelpers
  
    before do
      @association = stub_association(:foo)
      @records = [OpenStruct.new(:id => 3), OpenStruct.new(:id => 7), OpenStruct.new(:id => 2)]
      @association.stubs(:records).returns(@records)
    end
    
    it "should return a new array, using its own copies of the records where possible, when asked to merge into a superset of the records" do
      @superset = [OpenStruct.new(:id => 15), OpenStruct.new(:id => 56), OpenStruct.new(:id => 3),
                   OpenStruct.new(:id => 7),  OpenStruct.new(:id => 64), OpenStruct.new(:id => 2)]
      merged = @association.merge_into(@superset)
      
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
