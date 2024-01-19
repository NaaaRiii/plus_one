Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:4000'  # Reactアプリケーションのオリジン
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :delete, :options],
      credentials: true  # クッキーを含めるために必要
  end
end