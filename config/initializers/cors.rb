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
    origins 'https://plusoneup.net', 'https://www.plusoneup.net'
    resource '/api/*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true
  end
end