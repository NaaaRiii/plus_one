#Rails.application.config.middleware.insert_before 0, Rack::Cors do
#  allow do
#    origins 'http://localhost:4000'
#    resource '*',
#      headers: :any,
#      methods: [:get, :post, :patch, :put, :delete, :options, :head],
#      credentials: true
#  end
#end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://main.d18nq8a8fxeby3.amplifyapp.com/'  # Next.js の URL を許可

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true  # 認証情報を含むリクエストも許可する場合
  end
end
