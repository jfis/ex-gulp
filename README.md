# gulp

an exploration of elixir plug but for outbound web / http requests

maybe something like:

    defmodule GulpClient do
      use Gulp.Builder

      plug BaseUrl, "https://github.com"
      plug RequestId
      plug LoadOauthKeys
      plug Oauth
      plug RequestLogger
      plug Gulp.Adapter.Hackney
      plug ResponseLogger
      plug ResponseGulp

      #can also do named pipelines
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


      def default_pipeline(body) do
        post "/path1/path2", body: body
      end

      def named_pipeline(body) do
        post :alt, "/path1/path2", body: body
      end
    end
