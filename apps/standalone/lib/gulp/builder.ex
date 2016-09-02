defmodule Gulp.Builder do
  @moduledoc """
  """

  # @type gulp :: module | atom



  # def pipe_through(name) do
  #   IO.inspect name
  #
  #   quote do
  #     @test 1
  #   end
  # end

  # defmacro pipe_through(name, opts \\ []) do
  #   quote do
  #     pipeline = Module.get_attribute(__MODULE__, :pipeline) || :__pipeline_default
  #     @gulps {pipeline, {unquote(name), unquote(opts)}}
  #   end
  # end

  defmacro plug(name, opts \\ []) do
    quote do
      pipeline = Module.get_attribute(__MODULE__, :pipeline) || :__pipeline_default
      @gulps {pipeline, {unquote(name), unquote(opts)}}
    end
  end

  defmacro pipeline(group, do: block) do
    quote do
      old_pipeline = Module.get_attribute(__MODULE__, :pipeline)
      pipeline = old_pipeline || unquote(group) #ignore nested pipeline
      @pipeline pipeline
      unquote(block)
      @pipeline old_pipeline
    end
  end



  def make_conn(method, url, stuff) do
    body = Keyword.get(stuff, :body, %{})
    %Gulp.Conn{method: method, url: url}
  end
  #
  # def request(method, url, stuff) do
  #   request!(method, url, stuff)
  # end
  #
  # def request!(method, url, stuff) do
  #   # pipe_through(pipeline, conn, [])
  # end


  defmacro __using__(_options) do
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
      @behaviour Gulp

      def init(opts) do
        opts
      end

      def call(conn, opts) do
        # gulp_call(conn, opts)
        __pipeline_default(conn, opts)
      end

      defoverridable [init: 1, call: 2]



      unquote(http_methods)


      import unquote(__MODULE__)#, only: [gulp: 1, gulp: 2]
      Module.register_attribute(__MODULE__, :gulps, accumulate: true)
      @before_compile unquote(__MODULE__)

      @pipeline nil
    end
  end

  defmacro __before_compile__(env) do
    gulps = Module.get_attribute(env.module, :gulps)

    if gulps == [] do
      raise "no gulps have been defined in #{inspect env.module}"
    end

    groups =
      gulps |> Keyword.keys() |> Enum.sort |> Enum.uniq |> Enum.reverse


    for g <- groups do
      gulps = Keyword.get_values(gulps, g)
      {conn, body} = Gulp.Builder.compile(gulps)

      # {
      quote do
        defp unquote(g)(unquote(conn), _), do: unquote(body)
      # end, #|> Macro.to_string() |> IO.puts
      # quote do
        # defp pipe_through(unquote(g), conn, opts), do: unquote(g)(conn, opts)
      end
      # }
    end
    # |> Enum.reduce({[],[]}, fn({e1, e2}, {l1, l2}) -> {[e1 | l1], [e2 |l2]} end)
    # |> Tuple.to_list()
    # |> IO.inspect()
    # |> List.flatten()
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
      #<> ", all plugs must receive a connection (conn) and return a connection"

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
