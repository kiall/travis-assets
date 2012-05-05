require 'rack/file'

module Travis
  class Assets
    class Middleware
      autoload :Asset, 'travis/assets/middleware/asset'

      attr_accessor :app, :root, :files, :versions, :current

      def initialize(app, root)
        @app = app
        @root = root
        @files = Rack::File.new("#{root}/public")
        @versions = Travis::Assets.versions
        @current = Travis::Assets.version
      end

      def call(env)
        # Rebuilding assets on every request bumps the page reload time to ~15sec which
        # is unacceptable. Should use guard or something similar for asset dev instead.
        #
        # rebuild

        path = env['PATH_INFO']
        asset = Asset.new(root, path, versions, current)

        if path == '/current' or asset.serve?
          files.call(env)
        elsif asset.redirect?
          redirect_to(asset.current_path)
        else
          app.call(env)
        end
      end

      private

        def redirect_to(path)
          [301, { 'Content-Type' => 'text', 'Location' => path }, ['']]
        end

        def project
          Travis::Assets::Project.new(root)
        end

        def rebuild?
          !!options[:rebuild]
        end

        def rebuild
          @current = Travis::Assets.update_version
          project.invoke_clean
          @versions = Travis::Assets.versions
        end
    end
  end
end
