defmodule Gulp.Builder do
  defmacro __using__(_opts) do
    http_methods =
      for hm <- [:delete, :get, :head, :options, :patch, :post, :put, :trace] do
        quote do
          def unquote(hm)(url, stuff) do
            request(unquote(hm), url, stuff)
          end
        end
      end

    quote do
      use GenericPlug.Builder, pluggable: Gulp.Conn, behaviour: Gulp

      def request(method, url, stuff) do
        body = Keyword.get(stuff, :body, %{})
        %Gulp.Conn{method: method, url: url}
        |> call([])
      end

      unquote(http_methods)
    end
  end
end
