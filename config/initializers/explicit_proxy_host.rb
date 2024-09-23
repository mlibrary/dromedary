class ExplicitProxyHost
  def initialize(app)
    @app = app
    @host = ENV['RAILS_URL_HOST']
  end

  def call(env)
    env['HTTP_X_FORWARDED_HOST'] = @host unless @host.nil?
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before 0, ExplicitProxyHost
