require "yaml"
require "time"

module Feed2Gram
  Config = Struct.new(
    :feed_url,
    :facebook_app_id,
    :facebook_app_secret,
    :instagram_id,
    :access_token,
    :access_token_refreshed_at,
    keyword_init: true
  ) do
    def as_yaml
      to_h.transform_keys(&:to_s).to_yaml.gsub(/^---\n/, "")
    end
  end

  class LoadsConfig
    def load(config_path)
      yaml = YAML.load_file(config_path, permitted_classes: [Time])
      Config.new(**yaml)
    end
  end
end
