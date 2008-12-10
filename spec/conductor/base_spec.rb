require File.dirname(__FILE__) + '/../spec_helper'

describe Conductor::Base, "when conducting for a Task" do
  before do
    TaskConductor = Class.new(Conductor::Base)
    Task = Class.new
  end
  
  after do
    Object.send :remove_const, :TaskConductor
    Object.send :remove_const, :Task
  end
  
  it "should delegate unknown methods to the Task class, if the Task class responds to them" do
    Task.stubs(:foo).returns(foo = stub)
    TaskConductor.foo.should == foo
  end
  
  it "should raise a NoMethodError if asked for a method which neither it nor the Task responds to" do
    lambda { TaskConductor.bla }.should raise_error(NoMethodError)
  end
end

describe Conductor::Base, "when asked to conduct 'apples', with some options" do
  before do
    @conductor = Conductor::Base.new(stub_everything)
    @options = { :foo => :bar, :bing => :bong }
    (class << @conductor; self; end).conduct :apples, @options
  end
  
  it "should instantiate the apples updater with the given options" do
    @conductor.apples_updater.options.should == @options
  end
end

describe Conductor::Base, "with a resource, conducting 'memberships'" do
  before do
    @memberships = [stub_everything, stub_everything, stub_everything]
    @resource = stub_everything(:memberships => @people, :class => stub)
    @resource.class.stubs(:transaction).yields
    @conductor = Conductor::Base.new(@resource)
    (class << @conductor; self; end).conduct :memberships, :require_attribute => :member_id
  end
  
  it "should make the resource available as an attribute" do
    @conductor.resource.should == @resource
  end
  
  it "should run the memberships updater with the given params when memberships is assigned to" do
    @conductor.memberships_updater.expects(:run).with(params = stub)
    @conductor.memberships = params
  end
  
  it "should return the records of the memberhsips updater when asked for the memberships" do
    @conductor.memberships_updater.stubs(:records).returns(records = stub)
    @conductor.memberships.should == records
  end
  
  it "should return the potential memberships defined by the resource, merged into the memberships updater, when asked for the potential memberships" do
    resource_potential, potential = stub, stub
    @resource.stubs(:potential_memberships).returns(resource_potential)
    @conductor.memberships_updater.stubs(:merge_into).with(resource_potential).returns(potential)
    @conductor.potential_memberships.should == potential
  end
  
  it "should add the memberships updater to the list of updaters when memberships is assigned to" do
    @conductor.memberships = {}
    @conductor.updaters.should include(@conductor.memberships_updater)
  end
  
  it "should update the standard params on the resource when new attributes are assigned" do
    @resource.expects(:attributes=).with(:mordor => "evil", :shire => "stoners", :rivendell => "tall")
    @conductor.stubs(:memberships=)
    @conductor.attributes = { :mordor => "evil", :memberships => :bla, :shire => "stoners", :rivendell => "tall" }
  end
  
  it "should assign to the memberships when new attributes are assigned which contain a 'memberships' key" do
    @conductor.expects(:memberships=).with(:bla)
    @conductor.attributes = { :mordor => "evil", :memberships => :bla, :shire => "stoners", :rivendell => "tall" }
  end
  
  it "should not raise an exception if nil is assigned to the attributes" do
    lambda { @conductor.attributes = nil }.should_not raise_error
  end
  
  it "should clone the attributes given when the attributes are assigned" do
    params = { :raaa => :bar, :la => :na }
    cloned_params = params.clone
    params.expects(:clone).returns(cloned_params)
    @conductor.attributes = params
  end
  
  it "should assign the new attributes when asked to update_attributes" do
    @conductor.expects(:attributes=).with(params = stub)
    @conductor.update_attributes(params)
  end
  
  it "should save when asked to update_attributes" do
    @conductor.stubs(:memberships=)
    @conductor.expects(:save)
    @conductor.update_attributes :mordor => "evil", :memberships => :bla, :shire => "stoners", :rivendell => "tall"
  end
    
  it "should return true when update_attributes is successful and asked to update_attributes!" do
    @conductor.expects(:update_attributes).with(params = stub).returns(true)
    @conductor.update_attributes!(params).should == true
  end
    
  it "should raise a Conductor::ConductorInvalid exception when update_attributes is unsuccessful and asked to update_attributes!" do
    @conductor.expects(:update_attributes).with(params = stub).returns(false)
    
    begin
      @conductor.update_attributes!(params)
    rescue Conductor::ConductorInvalid => exception
      exception.conductor.should == @conductor
    end
  end
end

describe Conductor::Base, "when all the updaters and the resource are able to save!" do
  before do
    @resource = stub_everything(:class => stub_everything(:sequence_name => "the_sequence"), :save! => true)
    @resource.class.stubs(:transaction).yields
    
    @conductor = Conductor::Base.new(@resource)
    @conductor.updaters << stub_everything(:save! => true) << stub_everything(:save! => true)
    
    @connection = stub_everything
    @conductor.stubs(:connection).returns(@connection)
  end
  
  it "should start a transaction when saved" do
    @resource.class.expects(:transaction).yields
    @conductor.save
  end
  
  it "should return true when saved" do
    @conductor.save.should == true
  end
  
  it "should return true on save!" do
    @conductor.save!.should == true
  end

  describe "and the resource is a new record" do
    before do
      @resource.stubs(:new_record?).returns(true)
      @connection.stubs(:select_rows).with("SELECT nextval('the_sequence');").returns([["142"]]);
    end
    
    it "should run the before_save callback, defer the constraints, set the record's id, set the foreign keys on the updaters, " +
       "save! the updaters, save! the resource, then run the after_save callback, when saved" do
      save = sequence("save")
      @conductor.expects(:run_callbacks).with(:before_save).in_sequence(save)
      @connection.expects(:execute).with("SET CONSTRAINTS ALL DEFERRED;").in_sequence(save)
      @resource.expects(:id=).with(142).in_sequence(save)
      @conductor.updaters.each { |u| u.expects(:set_foreign_keys).in_sequence(save) }
      @conductor.updaters.each { |u| u.expects(:save!).in_sequence(save) }
      @resource.expects(:save!).in_sequence(save)
      @conductor.expects(:run_callbacks).with(:after_save).in_sequence(save)
      
      @conductor.save
    end
  end
  
  describe "and the resource is not a new record" do
    before do
      @resource.stubs(:new_record?).returns(false)
    end
  
    it "should run the before_save callback, save! the updaters, save! the resource, then run the after_save callback, when saved" do
      save = sequence("save")
      @conductor.expects(:run_callbacks).with(:before_save).in_sequence(save)
      @conductor.updaters.each { |u| u.expects(:save!).in_sequence(save) }
      @resource.expects(:save!).in_sequence(save)
      @conductor.expects(:run_callbacks).with(:after_save).in_sequence(save)
      
      @conductor.save
    end
  end
end

describe Conductor::Base, "when the resource is not able to save!" do
  before do
    @resource = stub_everything(:class => stub_everything(:sequence_name => "the_sequence"), :errors => stub_everything(:full_messages => stub_everything))
    @resource.stubs(:save!).raises(ActiveRecord::RecordInvalid.new(@resource))
    @resource.class.stubs(:transaction).yields
    
    @conductor = Conductor::Base.new(@resource)
    @conductor.updaters << stub_everything(:save! => true) << stub_everything(:save! => true)
    @conductor.updaters.each do |updater|
      updater.stubs(:records).returns([])
      rand(10).times { updater.records << stub_everything }
    end 
    
    @connection = stub_everything
    @conductor.stubs(:connection).returns(@connection)
  end

  it "should return false when saved" do
    @conductor.save.should == false
  end
  
  it "should call valid? for the resource and all of the records in the updater" do
    @resource.expects(:valid?)
    @conductor.updaters.each do |updater|
      updater.records.each do |record|
        record.expects(:valid?)
      end
    end
    @conductor.save
  end
  
  it "should raise a Conductor::ConductorInvalid exception on save!" do
    begin
      @conductor.save!
    rescue Conductor::ConductorInvalid => exception
      exception.conductor.should == @conductor
    end
  end
  
  describe "and the resource is a new record" do
    before do
      @resource.stubs(:new_record?).returns(true)
      @connection.stubs(:select_rows).with("SELECT nextval('the_sequence');").returns([["142"]]);
    end
    
    it "should set the id of the record back to nil when saved" do
      @resource.expects(:id=).with(nil)
      @conductor.save
    end
  end
end

describe Conductor::Base, "with a resource which responds to 'name' and 'age=', and has an id of 56" do
  before do
    @resource = stub_everything(:id => 56)
    @conductor = Conductor::Base.new(@resource)
  end
  
  it "should call the resource's name method when asked for the name" do
    @resource.stubs(:respond_to?).with(:name).returns(true)
    @resource.expects(:name).returns(name = stub)
    @conductor.name.should == name
  end
  
  it "should assign to the resource's age when the age is assigned to" do
    @resource.stubs(:respond_to?).with(:age=).returns(true)
    @resource.expects(:age=).with(73)
    @conductor.age = 73
  end
  
  it "should raise a NoMethodError when asked for its colour" do
    lambda { @conductor.colour }.should raise_error(NoMethodError)
  end
  
  it "should have an id of 56" do
    @conductor.id.should == 56
  end
end

describe Conductor::Base, "when the resource has error, and one of the records in an updater has an error" do
  before do
    @resource = stub_everything
    @resource.stubs(:errors).returns(ActiveRecord::Errors.new(@resource))
    @resource.errors.add_to_base "Foo is totally wrong!"
    
    @error_record = stub_everything
    @error_record.stubs(:errors).returns(ActiveRecord::Errors.new(@error_record))
    @error_record.errors.add_to_base "You are so stupid man!"
    
    @ok_record = stub_everything(:errors => stub_everything(:each_full => []))
    @updater = stub_everything(:records => [@ok_record.dup, @ok_record.dup, @error_record, @ok_record.dup])
    
    @conductor = Conductor::Base.new(@resource)
    @conductor.stubs(:updaters).returns([@updater])
  end
  
  it "should aggregate all the errors from the resource and the records in the updaters" do
    errors = @conductor.errors.full_messages
    errors.length.should == 2
    errors.should include("Foo is totally wrong!")
    errors.should include("You are so stupid man!")
  end
end
