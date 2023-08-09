# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'application#root'
  post '/graphql', to: 'graphql#execute'
  devise_for :users, only: []
  
end
