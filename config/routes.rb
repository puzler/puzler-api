Rails.application.routes.draw do
  root to: "application#root"
  mount GraphiQL::Rails::Engine, at: "/explorer", graphql_path: "/graphql"

  devise_for :users,
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations",
      passwords: "users/passwords",
      omniauth_callbacks: "users/omniauth_callbacks"
    }

  post "/graphql", to: "graphql#execute"

  put "/me/avatar", to: "users/avatars#update"
  delete "/me/avatar", to: "users/avatars#destroy"
  get "/me/export", to: "users/data_exports#show"

  # Action Cable WebSocket mount
  mount ActionCable.server => "/cable"

  get "up" => "rails/health#show", as: :rails_health_check
end
