require File.dirname(__FILE__) + "/../../spec_helper"

module Conductor::Associations
  describe HasMany::Builder, "with a name of 'tags' and some options, when built and an instance has been instantiated" do
    before do
      @conductor_class = Class.new
      @options = { :foo => :bar }
      @builder = HasMany::Builder.new(@conductor_class, :tags, @options)
      @builder.build
      
      @conductor, @instance = @conductor_class.new, stub
      HasMany.stubs(:new).with(@conductor, "tags", @options).returns(@instance)
      @builder.instantiate_instance(@conductor)
    end
    
    it "should provide a #tags method on the conductor which returns the instance's records" do
      records = stub
      @instance.stubs(:records).returns(records)
      @conductor.tags.should == records
    end
    
    it "should provide a #tags= method on the conductor, which parses the given params to the instance to be parsed" do
      params = stub
      @instance.expects(:parse).with(params)
      @conductor.tags = params
    end
  end
end
