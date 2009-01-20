require File.dirname(__FILE__) + '/../spec_helper'

module Conductor::Associations
  describe HasMany, "with a name of 'ducks': " do
    before do
      @association_proxy = DummyAssociationProxy.new
      @base_record = stub_everything(:ducks => @association_proxy)
      @conductor = stub_everything(:record => @base_record)
      @association = Conductor::Associations::HasMany.new(@conductor, :ducks)
    end
    
    describe "#base_record" do
      it "should return the conductor's record" do
        @association.base_record.should == @conductor.record
      end
    end
    
    it "should not be changed" do
      @conductor.should_not be_changed
    end
    
    describe "#reflection" do
      it "should return the base record's reflection for 'ducks'" do
        @base_record.stubs(:class).returns(stub_everything)
        @base_record.class.stubs(:reflect_on_association).with(:ducks).returns(reflection = stub)
        
        @association.reflection.should == reflection
      end
    end
    
    it "should be named 'ducks'" do
      @association.name.should == "ducks"
    end
    
    it "should return the base record's association proxy" do
      @association.proxy.should == @association_proxy
    end
    
    it "should store a copy of the original association proxy array" do
      original = @association_proxy.to_a
      @association_proxy << "lll"
      @association.original_records.should == original
    end
    
    it "should have an empty list of new records" do
      @association.new_records.should be_empty
    end
    
    it "should have an empty list of updated records" do
      @association.updated_records.should be_empty
    end
    
    it "should have an empty list of deleted records" do
      @association.deleted_records.should be_empty
    end
  end
  
  describe HasMany, "with a name of 'tables': " do
    before do
      @association = Conductor::Associations::HasMany.new(stub_everything, :tables)
      
      @reflection = stub_everything(:primary_key_name => 'table_id')
      @association.stubs(:reflection).returns(@reflection)
      
      @association_proxy = DummyAssociationProxy.new
      @association.stubs(:proxy).returns(@association_proxy)
    end
    
    describe "when given a hash of parameters to parse" do
      before do
        @association.parse(0 => { :id => 3 }, 1 => { :id => 8 })
      end
      
      it "should extract an array from the parameters" do
        @association.parameters.should == [{ :id => 3 }, { :id => 8 }]
      end
    end
    
    describe "when given parameters which require 1 addition, the deletion of records with id 6 and 9, " +
             "and the updating of the record with id 2" do
      before do
        @original_records = [
          DummyActiveRecord.new(:id => 6),                      # To be deleted
          DummyActiveRecord.new(:id => 2, "colour" => "green"), # To be updated
          DummyActiveRecord.new(:id => 9)                       # To be deleted
        ]
        @association.stubs(:original_records).returns(@original_records)
        @association.parse(
          1 => { "id" => "2", "colour" => "red" }, # Existing record
          2 => { "colour" => "orange" }            # New record
        )
      end
      
      it "should have 1 new record with the specified attributes" do
        @association.new_records.length.should == 1
        @association.new_records[0].colour.should == "orange"
      end
      
      it "should have updated the record with an id of 2 with the specified attributes" do
        @association.updated_records.length.should == 1
        @association.updated_records[0].should equal(@original_records[1])
        @association.updated_records[0].colour.should == "red"
      end
      
      it "should list the records with ids 6 and 9 as deleted" do
        @association.deleted_records.length.should == 2
        @association.deleted_records[0].should equal(@original_records[0])
        @association.deleted_records[1].should equal(@original_records[2])
      end
      
      it "should update the list of records to reflect the changes" do
        @association.records.should == @association.updated_records + @association.new_records
      end
      
      describe "#save!" do
        it "should delete all the deleted records from the association proxy" do
          @association_proxy.expects(:delete).with(*@association.deleted_records)
          @association.save!
        end
        
        it "should save! all the individual records" do
          @association.records.each { |record| record.expects(:save!) }
          @association.save!
        end
      end
      
      it "should be changed" do
        @association.should be_changed
      end
    end
  end
  
  describe HasMany, "with some records" do
    before do
      @association = Conductor::Associations::HasMany.new(stub_everything, :foo)
      @association.stubs(:records).returns([stub(:id => 4), stub(:id => 9), stub(:id => 1)])
    end
    
    it "should find a record when given an id that exists" do
      @association.find(1).should == @association.records[2]
    end
    
    it "should not find a record when given an id that does not exist" do
      @association.find(3).should == nil
    end
  end
end
