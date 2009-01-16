class BookConductor < Conductor::Base
  has_many :authorships, :require => :author_id
  
  def publisher=(publisher_name)
    @publisher = publisher_name
    resource.publisher = Publisher.find_by_name(@publisher)
  end
  
  def publisher
    @publisher || (resource.publisher && resource.publisher.name)
  end
end
