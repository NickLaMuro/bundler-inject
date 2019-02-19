module Bundler
  module Inject
    module DefinitionPatch
      def validate_runtime!
        Bundler::Inject.inject_from_definition_validation! self
        super
      end
    end
  end
end
