Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :accounts do
        post "auth/register", to: "auth#register"
        post "auth/login",    to: "auth#login"
        get  "auth/me",       to: "auth#me"
      end
    end
  end
end
