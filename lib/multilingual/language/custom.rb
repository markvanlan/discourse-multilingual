class Multilingual::CustomLanguage
  KEY ||= 'custom_language'.freeze
  ATTRS ||= [:name, :nativeName]
  
  def self.all
    Multilingual::Cache.wrap(KEY) do 
      result = {}
      
      PluginStoreRow.where("
        plugin_name = '#{Multilingual::PLUGIN_NAME}' AND
        key LIKE '#{Multilingual::CustomLanguage::KEY}_%'
      ").each do |record|
        begin
          code = record.key.split("#{Multilingual::CustomLanguage::KEY}_").last
          result[code] = JSON.parse(record.value)
        rescue JSON::ParserError => e
          puts e.message
        end
      end
      
      result
    end
  end

  def self.create(code, opts = {})
    if PluginStore.set(
      Multilingual::PLUGIN_NAME,
      "#{KEY}_#{code.to_s}",
      opts.with_indifferent_access.slice(*ATTRS)
    )
      after_create([code]) if opts[:run_hooks]
      true
    end
  end

  def self.destroy(code, opts = {})
    Multilingual::LanguageExclusion.set(code, 'interface', enabled: true)
    Multilingual::LanguageExclusion.set(code, 'content', enabled: true)
    
    if PluginStore.remove(Multilingual::PLUGIN_NAME, "#{KEY}_#{code.to_s}")
      after_destroy([code]) if opts[:run_hooks]
      true
    end
  end

  def self.after_create(created)
    Multilingual::ContentTag.bulk_update(created, "create")
    Multilingual::Language.after_change(created)
  end

  def self.after_destroy(destroyed)
    Multilingual::ContentTag.bulk_update(destroyed, "destroy")
    Multilingual::Language.after_change(destroyed)
  end
  
  def self.is_custom?(code)
    all.keys.include?(code.to_s)
  end
  
  def self.bulk_create(languages = {})
    created = []
    
    PluginStoreRow.transaction do
      languages.each do |k, v|
        if create(k, v)
          created.push(k)
        end
      end
      
      after_create(created)
    end
        
    created
  end
  
  def self.bulk_destroy(codes)
    destroyed = []
    
    PluginStoreRow.transaction do
      [*codes].each do |c|
        if destroy(c)
          destroyed.push(c)
        end
      end
      
      after_destroy(destroyed)
    end
        
    destroyed
  end
end