Rails.application.routes.draw do
  devise_for :users

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  root "home#index"

  # Employee PIN authentication routes
  get "employee/login", to: "employees#identification", as: "employee_login"
  post "employee/authenticate", to: "employees#authenticate", as: "employee_authenticate"
  delete "employee/logout", to: "employees#logout", as: "employee_logout"

  # Clock-in routes - selfie with GPS
  get "clock-in", to: "clock_in#show", as: "clock_in"
  post "clock-in", to: "clock_in#create", as: "create_clock_entry"

  # Admin routes
  namespace :admin do
    resources :face_enrollment, only: [ :index, :show, :destroy ] do
      member do
        post :enroll
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
