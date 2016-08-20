require 'rails'

module Contract
  class Engine < ::Rails::Engine
    isolate_namespace Contract

    initializer :append_migrations do |app|
    	unless app.root.to_s.match(root.to_s)
    		config.paths["db/migrate"].expanded.each do |p|
    			app.config.paths["db/migrate"] << p
    		end
    	end
    end

    initializer "contract", before: :load_config_initializers do |app|
      Rails.application.routes.append do
        mount Contract::Engine, at: "/contract"
      end
    end

    # initializer :assets do |config|
    #     Rails.application.config.assets.paths << root.join("app", "assets", "images")
    #     Rails.application.config.assets.paths << File.expand_path("../../assets/stylesheets", __FILE__)
    #     Rails.application.config.assets.paths << File.expand_path("../../assets/javascripts", __FILE__)
    #     Rails.application.config.assets.precompile += %w(*.css *.js)
    # end

    # config.local_asset_js_path = File.join(root, "vendor", "assets", "javascripts", "contract").to_s
    # config.local_asset_css_path = File.join(root, "vendor", "assets", "stylesheets", "contract").to_s
  end
end