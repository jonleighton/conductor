class Conductor::ActionView::FormBuilder < ActionView::Helpers::FormBuilder
  def fields_for_collection(name, records)
    raise ArgumentError, "No block given" unless block_given?
    
    # This ensures that records held by the conductor take precedence over records in the provided
    # collection, which allows us to maintain the state of the form if there are validation errors.
    # It depends on the association records having a sensible implementation of ==
    conductor_records = object.send(name).to_a
    records = records.map do |record|
      conductor_records.find { |conductor_record| record == conductor_record } || record
    end
    
    options = { :builder => Conductor::ActionView::CollectionFormBuilder, :collection => conductor_records }
    
    records.each_with_index do |record, i|
      @template.fields_for("#{object_name}[#{name}][#{i}]", record, options) do |fields|
        yield fields, record
        hidden_fields_for_end << fields.hidden_field(:id) unless fields.id_field_called?
      end
    end
  end
  
  def hidden_fields_for_end
    @hidden_fields_for_end ||= []
  end
  
  def string_for_end
    "<div style='margin:0;padding:0'>#{hidden_fields_for_end.join}</div>"
  end
end
