Rails.application.routes.draw do

  # get 'line', :to => 'home#handle_webhook'
  get 'line', :to => 'home#handle_webhook'

  post 'line', :to => 'home#handle_webhook'

end
