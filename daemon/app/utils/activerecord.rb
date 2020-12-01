module ActiveRecordPlugin
  def self.setup app
    if ENV['DATABASE_URL']
      app.database = ENV['DATABASE_URL']
    elsif File.exist?("#{Dir.pwd}/config/database.yml")
      app.database_file = "#{Dir.pwd}/config/database.yml"
    end

    unless defined?(Rake) || [:test, :production].include?(app.settings[:environment])
      ActiveRecord::Base.logger = Logger.new(STDOUT)
    end

    at_exit do
      ActiveRecord::Base.clear_active_connections!
      exit 0
    end
  end

  def database
    settings[:database]
  end

  module ClassMethods
    def database
      ActiveRecord::Base
    end
  
    def database=(spec)
      if spec.is_a?(Hash) and spec.symbolize_keys[environment.to_sym]
        ActiveRecord::Base.configurations = spec.stringify_keys
        ActiveRecord::Base.establish_connection(environment.to_sym)
      elsif spec.is_a?(Hash)     
        ActiveRecord::Base.configurations = {
          environment.to_s => spec.stringify_keys
        }
  
        ActiveRecord::Base.establish_connection(spec.stringify_keys)
      else
        if Gem.loaded_specs["activerecord"].version >= Gem::Version.create('6.0')
          ActiveRecord::Base.configurations ||= ActiveRecord::DatabaseConfigurations.new({}).resolve(spec)
        else
          ActiveRecord::Base.configurations ||= {}
          ActiveRecord::Base.configurations[environment.to_s] = ActiveRecord::ConnectionAdapters::ConnectionSpecification::ConnectionUrlResolver.new(spec).to_hash
        end
  
        ActiveRecord::Base.establish_connection(spec)
      end
    end
  
    def database_file=(path)
      path = File.join(root, path) if Pathname(path).relative? and root
      spec = YAML.load(ERB.new(File.read(path)).result) || {}
      self.database = spec
    end
  end
end
