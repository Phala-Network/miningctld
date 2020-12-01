typedefs = File.join APP_PATH, "substrate", "typedefs.json"
typedefs = File.open(typedefs).read
typedefs = JSON.parse(typedefs)

Scale::TypeRegistry.instance.load(custom_types: typedefs)
