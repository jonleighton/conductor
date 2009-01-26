require "action_view"

module Conductor::ActionView # :nodoc:
  require "conductor/action_view/helper"
  require "conductor/action_view/form_builder"
  require "conductor/action_view/collection_form_builder"
  require "conductor/action_view/collection_ids_form_builder"
end

ActionView::Base.send :include, Conductor::ActionView::Helper
