class BookConductor < Conductor::Base
  has_many :authorships, :require => :author_id
  
  def publisher=(publisher_name)
    resource.publisher = Publisher.find_by_name(publisher_name)
    @publisher = resource.publisher || publisher_name
  end
  
  def publisher
    @publisher || resource.publisher
  end
end
