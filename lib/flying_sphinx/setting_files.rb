class FlyingSphinx::SettingFiles
  INDEX_SETTINGS  = [:stopwords, :wordforms, :exceptions]
  SOURCE_SETTINGS = [:mysql_ssl_cert, :mysql_ssl_key, :mysql_ssl_ca]

  def initialize(indices = nil)
    @indices = indices ||
      ThinkingSphinx::Configuration.instance.configuration.indices
  end

  def upload_to(api)
    each_file_for_setting do |setting, file|
      api.post '/add_file',
        :setting   => setting.to_s,
        :file_name => File.basename(file),
        :content   => File.read(file)
    end
  end

  private

  attr_reader :indices

  def each_file_for_setting(&block)
    index_settings  &block
    source_settings &block
  end

  def index_settings(&block)
    settings_in_list_from_collection INDEX_SETTINGS, indices, &block
  end

  def sources
    @sources ||= indices.collect { |index|
      index.respond_to?(:sources) ? index.sources : []
    }.flatten
  end

  def source_settings(&block)
    settings_in_list_from_collection SOURCE_SETTINGS, sources, &block
  end

  def setting_from(collection, setting)
    collection.collect { |object|
      object.respond_to?(setting) ? object.send(setting).to_s.split(' ') : []
    }.flatten.uniq.compact
  end

  def settings_in_list_from_collection(settings, collection, &block)
    settings.each do |setting|
      setting_from(collection, setting).each { |file|
        block.call setting, file
      }
    end
  end
end
