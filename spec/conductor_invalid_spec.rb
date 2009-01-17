require File.dirname(__FILE__) + "/spec_helper"

describe Conductor::ConductorInvalid, "when initialized with a conductor" do
  before do
    @record = stub_everything
    @conductor = stub_everything(:record => @record)
    @exception = Conductor::ConductorInvalid.new(@conductor)
  end
  
  it "should make the conductor available as an attribute" do
    @exception.conductor.should == @conductor
  end
  
  it "should return the conductor's record when asked for the record" do
    @exception.record.should == @record
  end
end
