Rails.application.routes.draw do
  mount Rswag::Ui::Engine  => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      # ── Accounts ──────────────────────────────────────────────────── #
      namespace :accounts do
        scope :auth do
          post "register",                   to: "auth#register"
          post "verify-email",               to: "auth#verify_email"
          post "resend-verification-otp",    to: "auth#resend_verification_otp"
          post "send-password-reset-otp",    to: "auth#send_password_reset_otp"
          post "set-new-password",           to: "auth#set_new_password"
          post "login",                      to: "auth#login"
          post "login/verify",               to: "auth#login_verify"
          post "refresh",                    to: "auth#refresh"
          post "google-login",               to: "auth#google_login"
          post "logout",                     to: "auth#logout"
          post "biometrics/enable",          to: "auth#biometrics_enable"
          post "biometrics/login",           to: "auth#biometrics_login"
          post "biometrics/disable",         to: "auth#biometrics_disable"
          get  "me",                         to: "auth#me"
        end

        scope :profiles do
          get    "/",      to: "profiles#show"
          patch  "/",      to: "profiles#update"
          post   "avatar", to: "profiles#upload_avatar"
          delete "avatar", to: "profiles#remove_avatar"
        end
      end

      # ── Notifications ─────────────────────────────────────────────── #
      namespace :notifications do
        get   "/",        to: "notifications#index"
        patch ":id/read", to: "notifications#mark_read"
        patch "read-all", to: "notifications#mark_all_read"
      end

      # ── Wallets ───────────────────────────────────────────────────── #
      namespace :wallets do
        get  "/",           to: "wallets#index"
        get  ":currency",   to: "wallets#show"
        post "set-pin",     to: "wallets#set_pin"
        post "change-pin",  to: "wallets#change_pin"
        get  "rates",       to: "wallets#rates"
      end

      # ── Transactions ──────────────────────────────────────────────── #
      namespace :transactions do
        get  "/",           to: "transactions#index"
        get  ":reference",  to: "transactions#show"
        post "deposit",     to: "transactions#deposit"
        post "withdraw",    to: "transactions#withdraw"
        post "transfer",    to: "transactions#transfer"
      end

      # ── Cards ─────────────────────────────────────────────────────── #
      namespace :cards do
        get    "/",            to: "cards#index"
        post   "create",       to: "cards#create_virtual"
        post   ":id/freeze",   to: "cards#freeze"
        post   ":id/unfreeze", to: "cards#unfreeze"
        delete ":id",          to: "cards#destroy"
      end

      # ── Bills ─────────────────────────────────────────────────────── #
      namespace :bills do
        get  "providers", to: "bills#providers"
        get  "history",   to: "bills#history"
        post "pay",       to: "bills#pay"
      end

      # ── Payments (Links & Invoices) ───────────────────────────────── #
      namespace :payments do
        namespace :links do
          get  "/",    to: "payment_links#index"
          post "/",    to: "payment_links#create"
          get  "/:id", to: "payment_links#show"
        end

        namespace :invoices do
          get  "/",    to: "invoices#index"
          post "/",    to: "invoices#create"
          get  "/:id", to: "invoices#show"
        end
      end

      # ── Loans ─────────────────────────────────────────────────────── #
      namespace :loans do
        get  "/",           to: "loans#index"
        get  "products",    to: "loans#products"
        get  ":id/repayments", to: "loans#repayments"
        post "apply",       to: "loans#apply"
        post "repay",       to: "loans#repay"
      end

      # ── Investments ───────────────────────────────────────────────── #
      namespace :investments do
        get  "/",           to: "investments#index"
        get  "products",    to: "investments#products"
        post "invest",      to: "investments#invest"
        post "withdraw",    to: "investments#withdraw"
      end
    end
  end
end
