# gulp

an exploration of elixir plug but for outbound web / http requests

maybe something like:

    defmodule GulpClient do
      use Gulp.Builder

      plug BaseUrl
      plug RequestId
      plug LoadOauthKeys
      plug Oauth
      plug Gulp.Adapter.Hackney
      plug ResponseGulp

      plug :before do
        plug BaseUrl
        plug RequestId
        plug LoadOauthKeys
        plug Oauth
      end

      plug :after do
        plug ResponseGulp
      end

      plug :alt do
        plug :before
        plug Gulp.Adapter.Hackney
        plug :after
      end


      def normal() do
        post "/path1/path2", body: "param1"
      end

      def direct_pipeline() do
        post :alt, "/path1/path2", body: "param1", x: 111
      end
    end
