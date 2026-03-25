Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      # ── Users ──────────────────────────────────────────────────────────────
      scope :users do
        post 'register', to: 'users/registrations#create'
        post 'login',    to: 'users/sessions#create'
      end

      # ── Vendors ────────────────────────────────────────────────────────────
      scope :vendors do
        post 'register', to: 'vendors/registrations#create'
        post 'login',    to: 'vendors/sessions#create'
      end

      # ── Admin ──────────────────────────────────────────────────────────────
      scope :admin do
        post 'register', to: 'admin/registrations#create'
        post 'login',    to: 'admin/sessions#create'
      end

    end
  end
end