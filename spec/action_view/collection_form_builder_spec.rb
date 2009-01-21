require File.dirname(__FILE__) + "/spec_helper"

module Conductor::ActionView
  describe CollectionFormBuilder, "with a collection" do
    before do
      @collection = stub_everything
      @object = stub_everything
      @builder = CollectionFormBuilder.new(stub, @object, stub, { :collection => @collection }, stub)
    end
    
    describe "#inclusion_check_box" do
      it "should return a checked check_box if the object is included in the collection" do
        @collection.stubs(:include?).with(@object).returns(true)
        @builder.stubs(:check_box).with(:foo, { :checked => true }, anything, anything).returns(check_box = stub)
        
        @builder.inclusion_check_box(:foo).should == check_box
      end
      
      it "should return an unchecked check_box if the object is not included in the collection" do
        @collection.stubs(:include?).with(@object).returns(false)
        @builder.stubs(:check_box).with(:foo, { :checked => false }, anything, anything).returns(check_box = stub)
        
        @builder.inclusion_check_box(:foo).should == check_box
      end
    end
  end
  
  describe CollectionFormBuilder, "when the id field has not been called, but another field has: " do
    before do
      @builder = CollectionFormBuilder.new(stub_everything, stub_everything, stub_everything, {}, stub_everything)
      @builder.text_field :foo
    end
    
    describe "#id_field_called? " do
      it "should be false" do
        @builder.id_field_called?.should == false
      end
    end
  end
  
  describe CollectionFormBuilder, "when the id field has been called: " do
    before do
      @builder = CollectionFormBuilder.new(stub_everything, stub_everything, stub_everything, {}, stub_everything)
      @builder.check_box :id
    end
    
    describe "#id_field_called? " do
      it "should be true" do
        @builder.id_field_called?.should == true
      end
    end
  end
end
