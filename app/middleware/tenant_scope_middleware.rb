class TenantScopeMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    subdomain = request.subdomain

    if subdomain.present? && subdomain != "www"
      account = Account.find_by(subdomain: subdomain, active: true)

      if account
        Current.account = account
        @app.call(env)
      else
        # Invalid subdomain - could redirect to main site or show 404
        [ 404, { "Content-Type" => "text/plain" }, [ "Tenant not found" ] ]
      end
    else
      # No subdomain or www - allow normal processing
      @app.call(env)
    end
  ensure
    Current.account = nil
  end
end
