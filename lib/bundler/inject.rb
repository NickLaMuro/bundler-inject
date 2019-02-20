require "bundler/inject/version"

module Bundler
  module Inject
    class Source < ::Bundler::Plugin::API
      source "bundle_inject"

      def dependency_names_to_double_check
        []
      end
    end

    def inject!(builder)
      return if @injected
      @injected = true

      # Load the global and local bundler.d dirs
      load_bundler_d(builder, global_bundler_d)
      load_bundler_d(builder, local_bundler_d)
    end
    module_function :inject!

    def inject_from_definition_validation!(definition)
      builder = injection_builder nil, definition
      inject!(builder)
      update_definition(definition, builder)
    end
    module_function :inject_from_definition_validation!

    def inject_from_hook!(dependencies)
      builder = injection_builder(dependencies)
      inject!(builder)
    end
    module_function :inject_from_hook!

    def injection_builder(dependencies = nil, definition = Bundler.definition)
      # get a new Bundler::Dsl instance
      builder = Bundler::Dsl.new

      # Set the dependencies to the dependencies or pull from the existing
      # definition
      builder.dependencies = dependencies || definition.dependencies

      # Set the rest of the instance variables from Bundler.definition
      #
      # Based on Ruby's pass-by-reference design, we should be fine mutating
      # these in the new Builder, and it should be reflected in the
      # Bundler.definition in the end... hopefully...
      #
      # TODO:  Specs so we test this across bundler versions!
      #
      # (best we can do with the limited flexibility of Bundler::Plugin)
      sources         = definition.send(:sources)
      gemfiles        = definition.gemfiles
      ruby_version    = definition.send(:ruby_version)
      optional_groups = definition.instance_variable_get(:@optional_groups)

      builder.instance_variable_set(:@sources,         sources)
      builder.instance_variable_set(:@gemfiles,        gemfiles)
      builder.instance_variable_set(:@ruby_version,    ruby_version)
      builder.instance_variable_set(:@optional_groups, optional_groups)

      builder
    end
    module_function :injection_builder
    private_class_method :injection_builder

    def update_definition(definition, builder)
      lockfile = definition.lockfile
      unlock   = definition.instance_variable_get(:@unlock)

      new_definition = builder.to_definition(lockfile, unlock)

      # Copy definition vars to old definition
      #
      # Yes, this is a bit of a hack, but there is no better way (I can think
      # of) to trasfer the vars back to the definition we had passed in.

      copy_var definition, new_definition, :@unlocking_bundler
      copy_var definition, new_definition, :@unlocking
      copy_var definition, new_definition, :@unlock
      copy_var definition, new_definition, :@depenencies
      copy_var definition, new_definition, :@sources
      copy_var definition, new_definition, :@optional_groups
      copy_var definition, new_definition, :@remote
      copy_var definition, new_definition, :@specs
      copy_var definition, new_definition, :@ruby_version
      copy_var definition, new_definition, :@gemfiles
      copy_var definition, new_definition, :@lockfile
      copy_var definition, new_definition, :@lockfile_contents
      copy_var definition, new_definition, :@locked_bundler_version
      copy_var definition, new_definition, :@locked_ruby_version
      copy_var definition, new_definition, :@locked_specs_incomplete_for_platform
      copy_var definition, new_definition, :@lockfile_contents
      copy_var definition, new_definition, :@locked_platforms
      copy_var definition, new_definition, :@locked_deps
      copy_var definition, new_definition, :@locked_specs
      copy_var definition, new_definition, :@locked_sources
      copy_var definition, new_definition, :@platforms
      copy_var definition, new_definition, :@new_platform
      copy_var definition, new_definition, :@path_changes
      copy_var definition, new_definition, :@source_changes
      copy_var definition, new_definition, :@dependency_changes
      copy_var definition, new_definition, :@local_changes
      copy_var definition, new_definition, :@requires
    end
    module_function :update_definition
    private_class_method :update_definition

    def copy_var(definition, builder_definition, var)
      value = builder_definition.instance_variable_get(var)
      definition.instance_variable_set(var, value)
    end
    module_function :copy_var
    private_class_method :copy_var

    def load_bundler_d(builder, dir)
      Dir.glob(File.join(dir, '*.rb')).sort.each do |f|
        puts "Injecting #{f}..."
        builder.eval_gemfile(f, nil)
      end
    end
    module_function :load_bundler_d
    private_class_method :load_bundler_d

    def global_bundler_d
      File.join(Dir.home, ".bundler.d")
    end
    module_function :global_bundler_d
    private_class_method :global_bundler_d

    def local_bundler_d
      File.join(File.dirname(ENV["BUNDLE_GEMFILE"]), "bundler.d")
    end
    module_function :local_bundler_d
    private_class_method :local_bundler_d
  end
end

require 'bundler/inject/definition_patch'
Bundler::Definition.prepend(Bundler::Inject::DefinitionPatch)

Bundler::Plugin.add_hook('before-install-all') do |dependencies|
  require "bundler/inject/dsl_patch"

  Bundler::Dsl.prepend(Bundler::Inject::DslPatch)
  Bundler::Inject.inject! dependencies
end
