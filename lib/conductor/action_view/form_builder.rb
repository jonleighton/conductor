class Conductor::ActionView::FormBuilder < ActionView::Helpers::FormBuilder
  def fields_for_association(name, collection)
    raise ArgumentError, "No block given" unless block_given?
    
    collection.each_with_index do |item, i|
      @template.fields_for("#{object_name}[#{name}][#{i}]", item) do |fields|
        yield fields, item
      end
    end
  end
end
