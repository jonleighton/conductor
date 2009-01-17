require File.dirname(__FILE__) + '/spec_helper'

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
  
  describe "#has_many" do
    it "should instantiate a new Associations::HasMany::Builder, and tell it to build, then add it to the list of associations" do
      options, association = stub, stub
      Conductor::Associations::HasMany::Builder.stubs(:new).with(TaskConductor, :foo, options).returns(association)
      association.expects(:build)
      
      TaskConductor.has_many :foo, options
      TaskConductor.associations.should == [association]
    end
  end
  
  describe "#initialize" do
    before do
      @class_associations = [stub, stub, stub]
      @association_instances = [stub, stub, stub]
      @class_associations.each_with_index { |a, i| a.stubs(:instantiate_instance).with(anything).returns(@association_instances[i]) }
      TaskConductor.stubs(:associations).returns(@class_associations)
    end
    
    it "should initialize each of the associations and make their instances available" do
      @conductor = TaskConductor.new(stub)
      @conductor.associations.should == @association_instances
    end
  end
end

describe Conductor::Base, "with a record, with a has_many :memberships association" do
  before do
    @memberships = [stub_everything, stub_everything, stub_everything]
    @record = stub_everything(:memberships => @people, :class => stub)
    @record.class.stubs(:transaction).yields
    @conductor = Conductor::Base.new(@record)
    (class << @conductor; self; end).has_many :memberships, :require_attribute => :member_id
  end
  
  it "should make the record available as an attribute" do
    @conductor.record.should == @record
  end
  
  it "should update the standard params on the record when new attributes are assigned" do
    @record.expects(:attributes=).with(:mordor => "evil", :shire => "stoners", :rivendell => "tall")
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

describe Conductor::Base, "when all the associations and the record are able to save!" do
  before do
    @record = stub_everything(:class => stub_everything(:sequence_name => "the_sequence"), :save! => true)
    @record.class.stubs(:transaction).yields
    
    @conductor = Conductor::Base.new(@record)
    @conductor.associations << stub_everything(:save! => true) << stub_everything(:save! => true)
    
    @connection = stub_everything
    @conductor.stubs(:connection).returns(@connection)
  end
  
  it "should start a transaction when saved" do
    @record.class.expects(:transaction).yields
    @conductor.save
  end
  
  it "should return true when saved" do
    @conductor.save.should == true
  end
  
  it "should return true on save!" do
    @conductor.save!.should == true
  end

  describe "and the record is a new record" do
    before do
      @record.stubs(:new_record?).returns(true)
      @connection.stubs(:select_rows).with("SELECT nextval('the_sequence');").returns([["142"]]);
    end
    
    it "should run the before_save callback, defer the constraints, set the record's id, set the foreign keys on the associations, " +
       "save! the associations, save! the record, then run the after_save callback, when saved" do
      save = sequence("save")
      @conductor.expects(:run_callbacks).with(:before_save).in_sequence(save)
      @connection.expects(:execute).with("SET CONSTRAINTS ALL DEFERRED;").in_sequence(save)
      @record.expects(:id=).with(142).in_sequence(save)
      @conductor.associations.each { |a| a.expects(:set_foreign_keys).in_sequence(save) }
      @conductor.associations.each { |a| a.expects(:save!).in_sequence(save) }
      @record.expects(:save!).in_sequence(save)
      @conductor.expects(:run_callbacks).with(:after_save).in_sequence(save)
      
      @conductor.save
    end
  end
  
  describe "and the record is not a new record" do
    before do
      @record.stubs(:new_record?).returns(false)
    end
  
    it "should run the before_save callback, save! the associations, save! the record, then run the after_save callback, when saved" do
      save = sequence("save")
      @conductor.expects(:run_callbacks).with(:before_save).in_sequence(save)
      @conductor.associations.each { |a| a.expects(:save!).in_sequence(save) }
      @record.expects(:save!).in_sequence(save)
      @conductor.expects(:run_callbacks).with(:after_save).in_sequence(save)
      
      @conductor.save
    end
  end
end

describe Conductor::Base, "when the record is not able to save!" do
  before do
    @record = stub_everything(:class => stub_everything(:sequence_name => "the_sequence"), :errors => stub_everything(:full_messages => stub_everything))
    @record.stubs(:save!).raises(ActiveRecord::RecordInvalid.new(@record))
    @record.class.stubs(:transaction).yields
    
    @conductor = Conductor::Base.new(@record)
    @conductor.associations << stub_everything(:save! => true) << stub_everything(:save! => true)
    @conductor.associations.each do |association|
      association.stubs(:records).returns([])
      rand(10).times { association.records << stub_everything }
    end 
    
    @connection = stub_everything
    @conductor.stubs(:connection).returns(@connection)
  end

  it "should return false when saved" do
    @conductor.save.should == false
  end
  
  it "should call valid? for the record and all of the records in the association" do
    @record.expects(:valid?)
    @conductor.associations.each do |association|
      association.records.each do |record|
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
  
  describe "and the record is a new record" do
    before do
      @record.stubs(:new_record?).returns(true)
      @connection.stubs(:select_rows).with("SELECT nextval('the_sequence');").returns([["142"]]);
    end
    
    it "should set the id of the record back to nil when saved" do
      @record.expects(:id=).with(nil)
      @conductor.save
    end
  end
end

describe Conductor::Base, "with a record which responds to 'name' and 'age=', and has an id of 56" do
  before do
    @record = stub_everything(:id => 56)
    @conductor = Conductor::Base.new(@record)
  end
  
  it "should call the record's name method when asked for the name" do
    @record.stubs(:respond_to?).with(:name).returns(true)
    @record.expects(:name).returns(name = stub)
    @conductor.name.should == name
  end
  
  it "should assign to the record's age when the age is assigned to" do
    @record.stubs(:respond_to?).with(:age=).returns(true)
    @record.expects(:age=).with(73)
    @conductor.age = 73
  end
  
  it "should raise a NoMethodError when asked for its colour" do
    lambda { @conductor.colour }.should raise_error(NoMethodError)
  end
  
  it "should have an id of 56" do
    @conductor.id.should == 56
  end
end

describe Conductor::Base, "when the record has error, and one of the records in an association has an error" do
  before do
    @record = stub_everything
    @record.stubs(:errors).returns(ActiveRecord::Errors.new(@record))
    @record.errors.add_to_base "Foo is totally wrong!"
    
    @error_record = stub_everything
    @error_record.stubs(:errors).returns(ActiveRecord::Errors.new(@error_record))
    @error_record.errors.add_to_base "You are so stupid man!"
    
    @ok_record = stub_everything(:errors => stub_everything(:each_full => []))
    @association = stub_everything(:records => [@ok_record.dup, @ok_record.dup, @error_record, @ok_record.dup])
    
    @conductor = Conductor::Base.new(@record)
    @conductor.stubs(:associations).returns([@association])
  end
  
  it "should aggregate all the errors from the record and the records in the associations" do
    errors = @conductor.errors.full_messages
    errors.length.should == 2
    errors.should include("Foo is totally wrong!")
    errors.should include("You are so stupid man!")
  end
end
