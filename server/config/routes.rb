Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      scope :users do
        post 'register', to: 'users/registrations#create'
        post 'login',    to: 'users/sessions#create'
      end

      scope :vendors do
        post 'register', to: 'vendors/registrations#create'
        post 'login',    to: 'vendors/sessions#create'
      end

      scope :admin do
        post 'register', to: 'admin/registrations#create'
        post 'login',    to: 'admin/sessions#create'
      end

      resources :cities,    only: %i[index show create update destroy]
      resources :languages, only: %i[index show create update destroy]
      resources :formats,   only: %i[index show create update destroy]

      resources :movies,    only: %i[index show create update destroy]

      resources :theatres, only: %i[index show create update destroy] do
        resources :screens,  only: %i[index show create update destroy]
      end

    end
  end
end