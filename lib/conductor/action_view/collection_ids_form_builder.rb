class Conductor::ActionView::CollectionIdsFormBuilder
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  
  attr_reader :parent, :name, :object
  
  def initialize(parent, name, object)
    @parent, @name, @object = parent, name, object
  end
  
  %w(check_box hidden_field text_area text_field).each do |helper|
    class_eval <<-SRC
      def #{helper}(*args)
        #{helper}_tag(field_name, id, *args)
      end
    SRC
  end
  
  def label(text = nil, options = {})
    label_tag(field_id, text || object, options)
  end
  
  def inclusion_check_box(options = {})
    check_box_tag(field_name, id, parent_object.send(name).include?(id), :id => field_id)
  end
  
  private
  
    delegate :id, :to => :object
    delegate :object, :object_name, :to => :parent, :prefix => true
    
    def field_name
      "#{parent_object_name}[#{name}][]"
    end
    
    def field_id
      "#{parent_object_name}_#{name}_#{id}"
    end
end
