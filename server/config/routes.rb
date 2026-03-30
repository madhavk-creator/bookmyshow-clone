# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      # ── Auth ───────────────────────────────────────────────────────────────
      scope :users   do
        post 'register', to: 'users/registrations#create'
        post 'login',    to: 'users/sessions#create'
      end
      scope :vendors do
        post 'register', to: 'vendors/registrations#create'
        post 'login',    to: 'vendors/sessions#create'
      end
      scope :admin   do
        post 'register', to: 'admin/registrations#create'
        post 'login',    to: 'admin/sessions#create'
      end

      # ── Reference data ─────────────────────────────────────────────────────
      resources :cities,    only: %i[index show create update destroy]
      resources :languages, only: %i[index show create update destroy]
      resources :formats,   only: %i[index show create update destroy]

      # ── Movies ─────────────────────────────────────────────────────────────
      resources :movies, only: %i[index show create update destroy]

      # ── Theatres → Screens → Seat Layouts ──────────────────────────────────
      resources :theatres, only: %i[index show create update destroy] do
        resources :screens, only: %i[index show create update destroy] do
          resources :seat_layouts, only: %i[index show create update] do
            member do
              post :publish
              post :archive
              put  :sections,  action: :sync_sections
              put  :seats,     action: :sync_seats
            end
          end
        end
      end

    end
  end
end