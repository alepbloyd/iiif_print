# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 to add schemas that are located in config/metadata/*.yaml

module IiifPrint
  module SimpleSchemaLoaderDecorator
    def config_search_paths
      super + [IiifPrint::Engine.root]
    end
  end
end
