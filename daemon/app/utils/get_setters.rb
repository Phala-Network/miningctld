module GetSetterPlugin
  module ClassMethods
    def set(key, value)
      settings[key] = value
    end

    def get(key)
      settings[key]
    end
  end
end
