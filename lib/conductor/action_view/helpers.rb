module Conductor::ActionView::Helpers
  def form_for_conductor(conductor, *args, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    raise ArgumentError, "Object not a conductor" unless conductor.is_a?(Conductor::Base)
    
    options = args.extract_options!
    apply_form_for_options!(conductor.resource, options)
    options.merge!(:builder => Conductor::ActionView::FormBuilder)
    
    object_name = ActionController::RecordIdentifier.singular_class_name(conductor.resource)
    
    concat(form_tag(options.delete(:url) || {}, options.delete(:html) || {}), proc.binding)
    fields_for(object_name, conductor, *(args << options), &proc)
    concat('</form>', proc.binding)
  end
end
