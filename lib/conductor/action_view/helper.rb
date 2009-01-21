module Conductor::ActionView::Helper
  def form_for_conductor(conductor, *args, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    
    options = args.extract_options!
    apply_form_for_options!(conductor.record, options)
    options.merge!(:builder => Conductor::ActionView::FormBuilder)
    
    object_name = ActionController::RecordIdentifier.singular_class_name(conductor.record)
    
    concat(form_tag(options.delete(:url) || {}, options.delete(:html) || {}))
    fields_for(object_name, conductor, *(args << options)) do |fields|
      proc.call(fields)
      concat(fields.string_for_end)
    end
    concat('</form>')
  end
end
