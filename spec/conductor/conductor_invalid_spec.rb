require File.dirname(__FILE__) + "/../spec_helper"

describe Conductor::ConductorInvalid, "when initialized with a conductor" do
  before do
    @resource = stub_everything
    @conductor = stub_everything(:resource => @resource)
    @exception = Conductor::ConductorInvalid.new(@conductor)
  end
  
  it "should make the conductor available as an attribute" do
    @exception.conductor.should == @conductor
  end
  
  it "should return the conductor's resource when asked for the record" do
    @exception.record.should == @resource
  end
end
