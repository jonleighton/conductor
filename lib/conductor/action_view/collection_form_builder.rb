class Conductor::ActionView::CollectionFormBuilder < ActionView::Helpers::FormBuilder
  # An inclusion check box is checked if and only if the current record is contained in the collection
  def inclusion_check_box(name, options = {}, checked_value = "1", unchecked_value = "0")
    options.reverse_merge!(:checked => collection.include?(object))
    check_box(name, options, checked_value, unchecked_value)
  end
  
  private
  
    def collection
      options[:collection]
    end
end
