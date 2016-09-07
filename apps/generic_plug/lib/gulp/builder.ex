defmodule Gulp.Builder do
  defmacro __using__(_opts) do
    http_verbs = [:get, :post, :put, :patch, :delete, :options, :connect, :trace, :head]
    http_methods =
      for verb <- http_verbs do
        # verb! = verb |> to_string |> Kernel.<>("!") |> String.to_atom()
        # def unquote(verb)(url, stuff) do
        #   make_conn(verb, url, stuff)
        #   |> __pipeline_default([])
        #
        # end
        quote do
          defmacro unquote(verb)(url, stuff) do
            caller = Map.get(__CALLER__, :function)

            v = unquote(verb)
            quote do
              make_conn(unquote(v), unquote(url), unquote(stuff))
              |> Gulp.Conn.put_private(:caller, unquote(caller))
              |> __pipeline_default([])
            end
          end
          defmacro unquote(verb)(pipe, url, stuff) do
            caller = Map.get(__CALLER__, :function)
            v = unquote(verb)
            quote do
              make_conn(unquote(v), unquote(url), unquote(stuff))
              |> Gulp.Conn.put_private(:caller, unquote(caller))
              |> unquote(pipe)([])
            end
          end
        end

        # defmacro unquote(verb!)(url, stuff) do
        #   v = unquote(verb!)
        #   quote do
        #     make_conn(unquote(v), unquote(url), unquote(stuff))
        #     |> __pipeline_default([])
        #   end
        # end
        # defmacro unquote(verb!)(pipe, url, stuff) do
        #   v = unquote(verb!)
        #   quote do
        #     make_conn(unquote(v), unquote(url), unquote(stuff))
        #     |> unquote(pipe)([])
        #   end
        # end
      end

    quote do
      use GenericPlug.Builder, pluggable: Gulp.Conn, behaviour: Gulp

      unquote(http_methods)

      def request(method, url, stuff) do
        body = Keyword.get(stuff, :body, %{})
        %Gulp.Conn{method: method, url: url}
        |> call([])
      end

      def make_conn(method, url, stuff) do
        body = Keyword.get(stuff, :body, %{})
        %Gulp.Conn{method: method, url: url}
      end
    end
  end
end
