require "action_view"

module Conductor::ActionView
  require "conductor/action_view/helpers"
  require "conductor/action_view/form_builder"
end

ActionView::Base.send :include, Conductor::ActionView::Helpers
