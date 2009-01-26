# CollectionFormBuilder is a form builder which is used for the fields within a
# FormBuilder#fields_for_collection block. Each instance knows which record it is rendering fields for.
class Conductor::ActionView::CollectionFormBuilder < ActionView::Helpers::FormBuilder
  
  # An inclusion_check_box works the same way as a normal check_box, except that by default it
  # is checked if and only if the current record is contained in the collection.
  def inclusion_check_box(method, options = {}, checked_value = nil, unchecked_value = "")
    options.reverse_merge!(:checked => collection.include?(object))
    checked_value ||= object.send(method)
    
    check_box(method, options, checked_value, unchecked_value)
  end
  
  # Has the id field for the current record in the collection been called at all? Used to decide
  # whether to automatically write hidden id fields before the closing form tag.
  def id_field_called? # :nodoc:
    @id_field_called == true
  end
  
  %w(check_box hidden_field password_field radio_button text_area text_field).each do |helper|
    class_eval <<-SRC
      def #{helper}_with_id_call_logging(method, *args)    # def text_field_with_id_call_logging(method, *args)
        @id_field_called = true if method.to_sym == :id    #   @id_field_called = true if method.to_sym == :id
        #{helper}_without_id_call_logging(method, *args)   #   text_field_without_id_call_logging(method, *args)
      end                                                  # end
    SRC
    
    alias_method_chain helper, :id_call_logging
  end
  
  private
  
    def collection
      options[:collection]
    end
end
