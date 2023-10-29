module Feed2Gram
  class RefreshesToken
    def refresh!(config, config_path)
      return unless config.access_token_refreshed_at.nil? ||
        config.access_token_refreshed_at < Time.now - (60 * 60)

      data = Http.get("/oauth/access_token", {
        grant_type: "fb_exchange_token",
        client_id: config.facebook_app_id,
        client_secret: config.facebook_app_secret,
        fb_exchange_token: config.access_token
      })

      config.access_token = data[:access_token]
      config.access_token_refreshed_at = Time.now.utc

      File.write(config_path, config.as_yaml)
    end
  end
end
