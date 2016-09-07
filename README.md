# gulp

an exploration of elixir plug but for outbound web / http requests

maybe something like:

    defmodule GulpClient do
      use Gulp.Builder

      plug BaseUrl
      plug RequestId
      plug LoadOauthKeys
      plug Oauth
      plug RequestLogger
      plug Gulp.Adapter.Hackney
      plug ResponseLogger
      plug ResponseGulp

      plug :before do
        plug BaseUrl
        plug RequestId
        plug LoadOauthKeys
        plug Oauth
        plug RequestLogger
      end

      plug :after do
        plug ResponseLogger
        plug ResponseGulp
      end

      plug :alt do
        plug :before
        plug Gulp.Adapter.Hackney
        plug :after
      end


      def normal() do
        post "/path1/path2", body: "body"
      end

      def direct_pipeline() do
        post :alt, "/path1/path2", body: "body", options: [{"something", 1}]
      end
    end
