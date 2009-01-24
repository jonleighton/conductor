require File.dirname(__FILE__) + "/spec_helper"

module Conductor::ActionView
  describe FormBuilder, "for a book conductor" do
    before do
      @conductor = stub_everything
      @template = ActionView::Base.new
      @builder = FormBuilder.new("book", @conductor, @template, { }, stub)
    end
    
    it "should have an empty list of hidden fields for the end of the form" do
      @builder.hidden_fields_for_end.should == []
    end
    
    describe "#fields_for_collection" do
      it "should raise an ArgumentError if no block is given" do
        lambda { @builder.fields_for_collection(:foo, [stub, stub]) }.should raise_error(ArgumentError)
      end
      
      it "should merge the provided records with the records from the association with the given name " +
         "and then iterate those records yielding a fields block for each one which uses the CollectionFormBuilder" do
        conductor_records = [DummyActiveRecord.new(:id => 3), DummyActiveRecord.new(:id => 7)]
        records = [DummyActiveRecord.new(:id => 1), DummyActiveRecord.new(:id => 3), DummyActiveRecord.new(:id => 6), DummyActiveRecord.new(:id => 7)]
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
      
      it "should add a hidden id field to the list for the end of the form for each of the records which don't render their own id field" do
        records = [stub(:id => 4), stub(:id => 7)]
        hidden_field = stub
        @builder.fields_for_collection(:wallops, records) do |fields, record|
          if record == records[1]
            fields.text_field :id
          else
            fields.stubs(:hidden_field).with(:id).returns(hidden_field)
          end
        end
        
        @builder.hidden_fields_for_end.should == [hidden_field]
      end
    end
    
    describe "with some hidden fields for the end" do
      before do
        @builder.stubs(:hidden_fields_for_end).returns(["field1", "field2"])
      end
      
      describe "#string_for_end" do
        it "should join the fields together and put them in a div" do
          @builder.string_for_end.should == "<div style='margin:0;padding:0'>field1field2</div>"
        end
      end
    end
    
    describe "#fields_for_collection_ids" do
      it "should raise an ArgumentError if no block is given" do
        lambda { @builder.fields_for_collection_ids(:foo_ids, [stub, stub]) }.should raise_error(ArgumentError)
      end
      
      it "should yield a Conductor::ActionView::CollectionIdsFormBuilder and the record, for each of the records" do
        records = [stub, stub, stub]
        builders = records.map do |record|
          builder = stub
          Conductor::ActionView::CollectionIdsFormBuilder.stubs(:new).with(@builder, :foo_ids, record).returns(builder)
          builder
        end
        
        counter = 0
        @builder.fields_for_collection_ids(:foo_ids, records) do |fields, record|
          fields.should == builders[counter]
          record.should == records[counter]
          counter += 1
        end
        counter.should == 3
      end
    end
  end
end
