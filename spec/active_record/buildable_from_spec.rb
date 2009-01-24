require File.dirname(__FILE__) + "/spec_helper"

module Conductor::ActiveRecord
  describe "a class which is extended with BuildableFrom: " do
    before do
      @authorship_class = Class.new(OpenStruct)
      @authorship_class.send(:extend, BuildableFrom)
    end
    
    describe "#buildable_from :books" do
      before do
        @authorship_class.buildable_from(:books)
      end
    
      it "should create a build_from_book class method which should return a new instance linked to the given book" do
        book = stub(:id => 73)
        authorship = @authorship_class.build_from_book(book)
        authorship.should be_an_instance_of(@authorship_class)
        authorship.book_id.should == 73
      end
    
      it "should create a build_from_books class method which should call from_book on each of the arguments" do
        books = [stub, stub, stub]
        authorships = [stub, stub, stub]
        books.each_with_index { |book, index| @authorship_class.expects(:build_from_book).with(book).returns(authorships[index]) }
        
        @authorship_class.build_from_books(*books).should == authorships
      end
    end
  end
end
