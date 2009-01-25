class BooksController < ApplicationController
  # Add some before filters to initialize the @book and @book_conductor variables before the 
  # relevant actions
  before_filter :find_or_initialize_book, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :initialize_book_conductor, :only => [:new, :create, :edit, :update]
  
  def index
    @books = Book.find(:all)
  end
  
  # Instead of calling @book.update_attributes we do it on the @book_conductor. This causes the
  # conductor to take care of all the messy details of what changes should happen base on the 
  # params, and it will ensure the changes are all written to the database in one transaction.
  def create
    if @book_conductor.update_attributes(params[:book])
      redirect_to books_path
    else
      render :action => "new"
    end
  end
  
  def update
    if @book_conductor.update_attributes(params[:book])
      redirect_to books_path
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @book.destroy
    redirect_to books_path
  end
  
  private
  
    def find_or_initialize_book
      if params[:id]
        @book = Book.find(params[:id])
      else
        @book = Book.new
      end
    end
    
    # The conductor is initialized with the record it is supposed to be managing updates to
    def initialize_book_conductor
      @book_conductor = BookConductor.new(@book)
    end
end
