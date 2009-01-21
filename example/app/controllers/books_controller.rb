class BooksController < ApplicationController
  before_filter :find_or_initialize_book, :only => [:new, :create, :edit, :update, :destroy]
  before_filter :initialize_book_conductor, :only => [:new, :create, :edit, :update]

  def index
    @books = Book.find(:all)
  end
  
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
    
    def initialize_book_conductor
      @book_conductor = BookConductor.new(@book)
    end
end
