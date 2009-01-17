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
      end
    end
  end
end
