Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins Rails.env.production? ? ENV.fetch("FRONTEND_URL") : "*"

    resource "*",
      headers: :any,
      expose: ["Authorization"],
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
