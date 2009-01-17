require File.dirname(__FILE__) + "/../spec_helper"
require 'ostruct'

module Conductor::ActionView
  describe FormBuilder, "for a book conductor" do
    before do
      @conductor = stub_everything
      @template = ActionView::Base.new
      @builder = FormBuilder.new("book", @conductor, @template, { }, stub)
    end
    
    describe "#fields_for_collection" do
      it "should raise an ArgumentError if no block is given" do
        lambda { @builder.fields_for_collection(:foo, [stub, stub]) }.should raise_error(ArgumentError)
      end
      
      it "merge the provided records with the records from the association with the given name " +
         "and then iterate those records yielding a fields block for each one which uses the CollectionFormBuilder" do
        conductor_records = [OpenStruct.new(:id => 3), OpenStruct.new(:id => 7)]
        records = [OpenStruct.new(:id => 1), OpenStruct.new(:id => 3), OpenStruct.new(:id => 6), OpenStruct.new(:id => 7)]
        expected_records = [records[0], conductor_records[0], records[2], conductor_records[1]]
        @conductor.stubs(:carrots).returns(conductor_records)
        
        counter = 0
        @builder.fields_for_collection(:carrots, records) do |fields, record|
          fields.object_name.should == "book[carrots][#{counter}]"
          record.should equal(expected_records[counter])
          
          counter += 1
        end
        counter.should == 4
      end
    end
  end
end
