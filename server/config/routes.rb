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
      resources :cities,    only: %i[index shows create update destroy]
      resources :languages, only: %i[index shows create update destroy]
      resources :formats,   only: %i[index shows create update destroy]

      # ── Movies ─────────────────────────────────────────────────────────────
      resources :movies, only: %i[index shows create update destroy]

      # ── Shows (top-level discovery) ────────────────────────────────────────
      resources :shows, only: %i[index shows] do
        member do
          # Seat map + availability — primary data source for seat picker UI
          get 'seats', to: 'show_seats#availability'
          # Admin seat management
          post 'seats/:seat_id/block', to: 'show_seats#block', as: :block_seat
          delete 'seats/:seat_id/block', to: 'show_seats#unblock', as: :unblock_seat
        end
      end

      # ── Theatres → Screens → Seat Layouts + Shows ──────────────────────────
      resources :theatres, only: %i[index shows create update destroy] do
        resources :screens, only: %i[index shows create update destroy] do

          resources :seat_layouts, only: %i[index shows create update] do
            member do
              post :publish
              post :archive
              put  :sections, action: :sync_sections
              put  :seats,    action: :sync_seats
            end
          end

          resources :shows, only: %i[index shows create update] do
            member do
              post :cancel
            end
          end

        end
      end

    end
  end
end
