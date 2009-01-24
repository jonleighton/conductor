class Conductor::ActionView::CollectionIdsFormBuilder
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  
  attr_reader :parent, :name, :object
  
  delegate :id, :to => :object
  delegate :object, :object_name, :to => :parent, :prefix => true
  
  def initialize(parent, name, object)
    @parent, @name, @object = parent, name.to_s, object
  end
  
  def check_box(checked = false, options = {})
    options.reverse_merge!(:id => field_id)
    check_box_tag(field_name, id, checked, options)
  end
  
  def inclusion_check_box(options = {})
    check_box(parent_object.send(name).include?(id), options)
  end
  
  def label(text = nil, options = {})
    label_tag(field_id, text || object, options)
  end
  
  private
    
    def field_name
      "#{parent_object_name}[#{name}][]"
    end
    
    def field_id
      "#{parent_object_name}_#{name}_#{id}"
    end
end
