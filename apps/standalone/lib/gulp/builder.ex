defmodule Gulp.Builder do
  @moduledoc """
  """

  @type gulp :: module | atom

  defmacro gulp(name, opts \\ []) do
    quote do
      @gulps {unquote(name), unquote(opts)}
    end
  end

  defmacro __using__(_options) do
    http_methods =
      for hm <- [:delete, :get, :head, :options, :patch, :post, :put, :trace] do
        quote do
          def unquote(hm)(url, stuff) do
            request(unquote(hm), url, stuff)
          end
        end
      end

    quote do
      @behaviour Gulp

      def init(opts) do
        opts
      end

      def call(conn, opts) do
        gulp_call(conn, opts)
      end

      defoverridable [init: 1, call: 2]



      def request(method, url, stuff) do
        body = Keyword.get(stuff, :body, %{})
        %Gulp.Conn{method: method, url: url}
        |> call([])
      end

      unquote(http_methods)



      import unquote(__MODULE__)#, only: [gulp: 1, gulp: 2]
      Module.register_attribute(__MODULE__, :gulps, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    gulps = Module.get_attribute(env.module, :gulps)

    if gulps == [] do
      raise "no gulps have been defined in #{inspect env.module}"
    end

    {conn, body} = Gulp.compile(gulps)

    quote do
      defp gulp_call(unquote(conn), _), do: unquote(body)
    end
  end

  def compile(pipeline) do
    conn = quote do: conn
    {conn, Enum.reduce(pipeline, conn, &quote_plug(init_plug(&1), &2))} #just go with plug hereon
  end

  defp init_plug({plug, opts}) do
    case Atom.to_char_list(plug) do #this should be something like Atom.module?
      ~c"Elixir." ++ _ ->
        init_module_plug(plug, opts)
      _ ->
        {:function, plug, opts}
    end
  end

  defp init_module_plug(plug, opts) do
    initialized_opts = plug.init(opts) #compile time call to module plug init

    if function_exported?(plug, :call, 2) do #check if module exports call/2
      {:module, plug, initialized_opts}
    else
      raise ArgumentError, message: "#{inspect plug} plug must implement call/2"
    end
  end

  # `acc` is a series of nested plug calls in the form of
  # plug3(plug2(plug1(conn))). `quote_plug` wraps a new plug around that series
  # of calls.
  defp quote_plug({plug_type, plug, opts}, acc) do
    call = quote_plug_call(plug_type, plug, opts)

    error_message =
      case plug_type do
        :module   -> "expected #{inspect plug}.call/2 to return a Gulp.Conn"
        :function -> "expected #{plug}/2 to return a Gulp.Conn"
      end
      <> ", all plugs must receive a connection (conn) and return a connection"

    quote do
      case unquote(call) do
        %Gulp.Conn{halted: true} = conn ->
          IO.puts "halted"
          # unquote(log_halt(plug_type, plug, env))
          conn
        %Gulp.Conn{} = conn ->
          unquote(acc)
        _ ->
          raise unquote(error_message)
      end
    end
  end

  defp quote_plug_call(:function, plug, opts) do
    quote do: unquote(plug)(conn, unquote(Macro.escape(opts))) #bc could be nonliteral
  end

  defp quote_plug_call(:module, plug, opts) do
    quote do: unquote(plug).call(conn, unquote(Macro.escape(opts)))
  end
end
