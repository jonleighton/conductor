module Conductor::ActionView::Helper
  def form_for_conductor(conductor, *args, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    
    options = args.extract_options!
    apply_form_for_options!(conductor.record, options)
    options.merge!(:builder => Conductor::ActionView::FormBuilder)
    
    concat(form_tag(options.delete(:url) || {}, options.delete(:html) || {}))
    fields_for(conductor.record_name, conductor, *(args << options)) do |fields|
      proc.call(fields)
      concat(fields.string_for_end)
    end
    concat('</form>')
  end
  
  def error_messages_for_conductor(conductor_name, *args)
    conductor = instance_variable_get("@#{conductor_name}")
    
    options = args.extract_options!
    options.reverse_merge!(:object_name => conductor.record_name)
    args << options
    
    error_messages_for(conductor_name, *args)
  end
end
