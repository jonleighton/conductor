require File.dirname(__FILE__) + "/spec_helper"

module Conductor::ActionView
  describe Helper do
    before do
      @helper = Object.new
      (class << @helper; self; end).class_eval do
        include Helper
      end
    end
    
    describe "#form_for_conductor" do
      before do
        @conductor = stub_everything(:record => stub_everything)
        ActionController::RecordIdentifier.stubs(:singular_class_name).with(@conductor.record).returns("time_warp")
      end
    
      it "should raise an ArgumentError if there is no block" do
        lambda { @helper.form_for_conductor(stub) }.should raise_error(ArgumentError)
      end
      
      it "should create a form using Conductor::ActionView::FormBuilder, " +
         "which uses the conductor as the object, but the conductor's record for the object name" do
        original_options = { :url => "/jump/to/the/left", :step_to => :the_right }
        fields_for_options = { :step_to => :the_right, :builder => Conductor::ActionView::FormBuilder }
        @helper.expects(:apply_form_for_options!).with(@conductor.record, original_options)
        
        @helper.stubs(:form_tag).with("/jump/to/the/left", {}).returns(form_tag = stub)
        
        fields = stub_everything
        form_seq = sequence("form")
        
        @helper.expects(:concat).with(form_tag, anything).in_sequence(form_seq)
        
        @helper.expects(:fields_for).with(
          "time_warp", @conductor,
          :hands_on_hips, :knees_in_tight,
          fields_for_options
        ).yields(fields).in_sequence(form_seq)
        
        # See below, the block calls this method to indicate it is actually used. Oh for a better
        # solution...
        fields.expects(:block_called).in_sequence(form_seq)
        
        fields.stubs(:string_for_end).returns(string_for_end = stub)
        @helper.expects(:concat).with(string_for_end, anything).in_sequence(form_seq)
        
        @helper.expects(:concat).with("</form>", anything).in_sequence(form_seq)
        
        @helper.form_for_conductor(@conductor, :hands_on_hips, :knees_in_tight, original_options) do
          fields.block_called
        end
      end
      
      
    end
  end
end
