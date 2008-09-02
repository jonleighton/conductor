class ActionView::Base
  def apply_form_for_options_with_conductor_support!(object_or_array, options)
    if object_or_array.is_a? Array
      object = object_or_array.pop
      object = object.resource if object.is_a? Conductor::Base
      object_or_array << object
    else
      object_or_array = object_or_array.resource if object_or_array.is_a? Conductor::Base
    end
    
    apply_form_for_options_without_conductor_support!(object_or_array, options)
  end
  alias_method_chain :apply_form_for_options!, :conductor_support
end
