begin
  require "sidekiq/web"
rescue LoadError
  # Sidekiq web UI is optional in environments where the web component is unavailable.
end

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # ── Auth ───────────────────────────────────────────────────────────────
      scope :users   do
        post "register", to: "users/registrations#create"
        post "login",    to: "users/sessions#create"
        patch "profile",  to: "users/profiles#update"
        patch "password", to: "users/profiles#update_password"
      end
      scope :vendors do
        post "register", to: "vendors/registrations#create"
        post "login",    to: "vendors/sessions#create"
        patch "profile",  to: "vendors/profiles#update"
        patch "password", to: "vendors/profiles#update_password"
      end
      scope :admin   do
        post "register", to: "admin/registrations#create"
        post "login",    to: "admin/sessions#create"
        patch "profile",  to: "admin/profiles#update"
        patch "password", to: "admin/profiles#update_password"
        resources :coupons, only: %i[index create destroy], module: "admin"
      end

      # ── Reference data ─────────────────────────────────────────────────────
      get "coupons", to: "coupons#index"
      get "coupons/:code/validate", to: "coupons#validate"

      resources :vendors, only: %i[index] do
        member do
          get :income
        end
      end

      resources :cities,    only: %i[index show create update destroy]
      resources :languages, only: %i[index show create update destroy]
      resources :formats,   only: %i[index show create update destroy]

      # ── Movies ─────────────────────────────────────────────────────────────
      resources :movies, only: %i[index show create update destroy] do
        resources :reviews, only: %i[index show create update destroy]
      end

      # ── Shows (top-level discovery) ────────────────────────────────────────
      resources :shows, only: %i[index show] do
        member do
          # Seat map + availability — primary data source for seat picker UI
          get "seats", to: "show_seats#availability"
          # Admin seat management
          post "seats/:seat_id/block", to: "show_seats#block", as: :block_seat
          delete "seats/:seat_id/block", to: "show_seats#unblock", as: :unblock_seat
        end
      end

      # ── Bookings ───────────────────────────────────────────────────────────
      resources :bookings, only: %i[index show create] do
        member do
          post "confirm_payment"
          post "cancel"
          post "apply_coupon"
          post "tickets/:ticket_id/cancel", action: :cancel_ticket, as: :cancel_ticket
        end
      end

      # ── Theatres → Screens → Seat Layouts + Shows ──────────────────────────
      resources :theatres, only: %i[index show create update destroy] do
        resources :screens, only: %i[index show create update destroy] do
          resources :seat_layouts, only: %i[index show create update] do
            member do
              post :publish
              post :archive
              put  :sections, action: :sync_sections
              put  :seats,    action: :sync_seats
            end
          end

          resources :shows, only: %i[index show create update] do
            member do
              post :cancel
            end
          end
        end
      end
    end
    # ── Sidekiq dashboard (admin only) ─────────────────────────────────────────
    authenticate :user, ->(u) { u.admin? } do
      next unless defined?(Sidekiq::Web)

      mount Sidekiq::Web => "/sidekiq"
    end
  end
end
