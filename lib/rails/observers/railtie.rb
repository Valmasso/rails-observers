require 'rails/railtie'

module Rails
  module Observers
    class Railtie < ::Rails::Railtie
      initializer "action_controller.caching.sweepers" do
        ActiveSupport.on_load(:action_controller) do
          require "rails/observers/action_controller/caching"
        end
      end

      initializer "active_resource.observer" do |app|
        ActiveSupport.on_load(:active_resource) do
          require 'rails/observers/active_resource/observing'

          prepend ActiveResource::Observing
        end
      end

      config.after_initialize do |app|
        begin
          # Eager load `ActiveRecord::Base` to avoid circular references when
          # loading a constant for the first time.
          #
          # E.g. loading a `User` model that references `ActiveRecord::Base`
          # which calls `instantiate_observers` to instantiate a `UserObserver`
          # which eventually calls `observed_class` thus constantizing `"User"`,
          # the class we're loading. 💣💥
          require "active_record/base" if defined?(ActiveRecord)
        rescue LoadError
        end

        ActiveSupport.on_load(:active_resource) do
          self.instantiate_observers

          # Rails 5.1 forward-compat. AD::R is deprecated to AS::R in Rails 5.
          reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader
          reloader.to_prepare do
            ActiveResource::Base.instantiate_observers
          end
        end
      end
    end
  end
end
