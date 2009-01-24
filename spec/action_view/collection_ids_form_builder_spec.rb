require File.dirname(__FILE__) + "/spec_helper"

module Conductor::ActionView
  describe CollectionIdsFormBuilder, "with a parent whose object name is 'book', a name of 'tag_ids' and an object with id 72: " do
    before do
      @parent = stub_everything(:object_name => 'book', :object => stub_everything)
      @object = stub_everything(:id => 72)
      @builder = CollectionIdsFormBuilder.new(@parent, :tag_ids, @object)
    end
    
    describe "#check_box" do
      it "should create a check_box_tag with a name of 'book[tag_ids][]', an id of 'book_tag_ids_72' and a value of the object's id" do
        check_box = stub
        @builder.stubs(:check_box_tag).with('book[tag_ids][]', 72, true, :id => 'book_tag_ids_72', :foo => :bar).returns(check_box)
        
        @builder.check_box(true, :foo => :bar).should == check_box
      end
    end
    
    describe "#inclusion_check_box" do
      it "should call check_box specifying it to be checked if the id is included in the association ids" do
        check_box = stub
        @parent.object.stubs(:tag_ids).returns([4, 76, 3])
        @builder.stubs(:check_box).with(false, :foo => :bar).returns(check_box)
        
        @builder.inclusion_check_box(:foo => :bar).should == check_box
      end
    end
    
    describe "#label" do
      it "should create a label for the 'book_tag_ids_72' using the object for the value if no text is given" do
        label = stub
        @builder.stubs(:label_tag).with('book_tag_ids_72', @object, {}).returns(label)
        
        @builder.label.should == label
      end
      
      it "should use the specified text and options for the label if they are provided" do
        label = stub
        @builder.stubs(:label_tag).with('book_tag_ids_72', "A label", :foo => :bar).returns(label)
        
        @builder.label("A label", :foo => :bar).should == label
      end
    end
  end
end
