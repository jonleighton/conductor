class BookConductor < Conductor::Base
  has_many :authorships, :require => :author_id
  
  def publisher=(publisher_name)
    record.publisher = Publisher.find_by_name(publisher_name)
    @publisher = record.publisher || publisher_name
  end
  
  def publisher
    @publisher || record.publisher
  end
end
