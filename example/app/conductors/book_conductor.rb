class BookConductor < Conductor::Base
  # This states that we want to manage a "tags" association. There is no difference between how
  # different types of one-to-many associations are handled, so there is no has_and_belongs_to_many
  # for Conductors.
  has_many :tags
  
  # Here we require an "author_id" to be present in the parameters before we consider a given
  # authorship to be associated. This happens when the checkbox for a given authorship is checked
  # in the form, therefore passing along the author id.
  has_many :authorships, :require => :author_id
  
  # Here's a "manual" way of using conductor; defining an attribute setter which does something with
  # the value before changing the underlying record. In this case we are finding the Publisher
  # by name.
  def publisher=(publisher_name)
    record.publisher = Publisher.find_by_name(publisher_name)
    @publisher = record.publisher || publisher_name
  end
  
  def publisher
    @publisher || record.publisher
  end
end
