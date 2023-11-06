module Feed2Gram
  class RefreshesToken
    def refresh!(config, options)
      return unless config.access_token_refreshed_at.nil? ||
        config.access_token_refreshed_at < Time.now - (60 * 60)

      puts "Refreshing Facebook OAuth token" if options.verbose
      data = Http.get("/oauth/access_token", {
        grant_type: "fb_exchange_token",
        client_id: config.facebook_app_id,
        client_secret: config.facebook_app_secret,
        fb_exchange_token: config.access_token
      })

      config.access_token = data[:access_token]
      config.access_token_refreshed_at = Time.now.utc

      puts "Updating Facebook OAuth token in: #{options.config_path}" if options.verbose
      File.write(options.config_path, config.as_yaml)
    end
  end
end
