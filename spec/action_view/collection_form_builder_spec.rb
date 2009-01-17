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
end
