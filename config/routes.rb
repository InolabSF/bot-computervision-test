Rails.application.routes.draw do

  # get 'line', :to => 'home#handle_webhook'
  get 'line', :to => 'home#test_get'

  post 'line', :to => 'home#post_line'

end
