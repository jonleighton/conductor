ActionController::Routing::Routes.draw do |map|
  map.resources :books
  map.connect "/", :controller => "books"
end
