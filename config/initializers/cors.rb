Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:4000'  # Next.jsサーバーのオリジン
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :delete, :options]
  end
end
