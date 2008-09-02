require File.dirname(__FILE__) + "/../spec_helper"

describe ActionView::Base, "with a task_conductor" do
  before do
    @view = ActionView::Base.new
    @view.stubs(:concat)
    
    @task = stub_everything("task", :id => 84)
    @conductor = stub_everything("conductor", :resource => @task)
    @conductor.stubs(:is_a?).with(Conductor::Base).returns(true)
  end
  
  # Note: I had trouble working out why the @task gets turned into an array if there is a non-array
  # argument to form_for, but it doesn't essentially matter...
  
  describe "when the task is a new record" do
    before do
      @task.stubs(:new_record?).returns(true)
    end
    
    it "should call form_tag with the polymorphic path for the task and post as the method when asked for a form_for the conductor" do
      @view.stubs(:polymorphic_path).with([@task]).returns(polymorphic_path = stub)
      @view.expects(:form_tag).with(polymorphic_path, has_entry(:method => :post), anything)
      @view.form_for(@conductor) { }
    end
  end
  
  describe "when the task is a new record and the conductor is passed as the last item in an array" do
    before do
      @task.stubs(:new_record?).returns(true)
    end
    
    it "should call form_tag with the polymorphic path for the task and post as the method when asked for a form_for the conductor" do
      args = [stub, stub, @conductor]
      @view.stubs(:polymorphic_path).with(args).returns(polymorphic_path = stub)
      @view.expects(:form_tag).with(polymorphic_path, has_entry(:method => :post), anything)
      @view.form_for(args) { }
    end
  end
  
  describe "when the task is not a new record" do
    before do
      @task.stubs(:new_record?).returns(false)
    end
    
    it "should call form_tag with the polymorphic path for the task and put as the method when asked for a form_for the conductor" do
      @view.stubs(:polymorphic_path).with([@task]).returns(polymorphic_path = stub)
      @view.expects(:form_tag).with(polymorphic_path, has_entry(:method => :put), anything)
      @view.form_for(@conductor) { }
    end
  end
end
