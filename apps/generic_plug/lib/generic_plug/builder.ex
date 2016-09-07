defmodule GenericPlug.Builder do
  @moduledoc """
  """

  @type plug :: module | atom

  @doc """
  """
  defmacro plug(pipeline_name, opts \\ [])
  defmacro plug(pipeline_name, do: block) do
    quote do
      old_pipeline = Module.get_attribute(__MODULE__, :pipeline)
      pipeline = old_pipeline || unquote(pipeline_name) #ignore nested pipeline
      @pipeline pipeline
      unquote(block)
      @pipeline old_pipeline
    end
  end

  defmacro plug(plug, opts) do
    quote do
      pipeline = Module.get_attribute(__MODULE__, :pipeline) || :__pipeline_default
      @plugs {pipeline, {unquote(plug), unquote(opts), true}}
    end
  end



  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour unquote(opts[:behaviour])
      @plug_builder_opts unquote(opts)

      def init(opts) do
        opts
      end

      def call(pluggable, opts) do
        __pipeline_default(pluggable, opts)
      end

      defoverridable [init: 1, call: 2]

      import unquote(opts[:pluggable])
      import GenericPlug.Builder, only: [plug: 1, plug: 2]

      Module.register_attribute(__MODULE__, :plugs, accumulate: true)
      @before_compile GenericPlug.Builder

      @pipeline nil
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    plugs        = Module.get_attribute(env.module, :plugs)
    builder_opts = Module.get_attribute(env.module, :plug_builder_opts)

    pluggableMod = builder_opts[:pluggable]

    if plugs == [] do
      raise "no plugs have been defined in #{inspect env.module}"
    end

    pipelines =
      plugs |> Keyword.keys() |> Enum.sort |> Enum.uniq |> Enum.reverse


    for p <- pipelines do
      plugs_in_pipeline = Keyword.get_values(plugs, p)
      {pluggable, body} = GenericPlug.Builder.compile(pluggableMod, env, plugs_in_pipeline, builder_opts)

      quote do
        defp unquote(p)(unquote(pluggable), _), do: unquote(body)
      end
    end

    # {pluggable, body} = GenericPlug.Builder.compile(pluggableMod, env, plugs, builder_opts)
    #
    # quote do
    #   defp plug_builder_call(unquote(pluggable), _), do: unquote(body)
    # end
  end


  @doc """
  """
  def compile(pluggableMod, env, pipeline, builder_opts) do
    pluggable = quote do: pluggable
    {pluggable, Enum.reduce(pipeline, pluggable, &quote_plug(pluggableMod, init_plug(&1), &2, env, builder_opts))}
  end

  # Initializes the options of a plug at compile time.
  defp init_plug({plug, opts, guards}) do
    case Atom.to_char_list(plug) do
      ~c"Elixir." ++ _ -> init_module_plug(plug, opts, guards)
      _                -> init_fun_plug(plug, opts, guards)
    end
  end

  defp init_module_plug(plug, opts, guards) do
    initialized_opts = plug.init(opts)

    if function_exported?(plug, :call, 2) do
      {:module, plug, initialized_opts, guards}
    else
      raise ArgumentError, message: "#{inspect plug} plug must implement call/2"
    end
  end

  defp init_fun_plug(plug, opts, guards) do
    {:function, plug, opts, guards}
  end

  # `acc` is a series of nested plug calls in the form of
  # plug3(plug2(plug1(pluggable))). `quote_plug` wraps a new plug around that series
  # of calls.
  defp quote_plug(pluggableMod, {plug_type, plug, opts, guards}, acc, env, builder_opts) do
    call = quote_plug_call(plug_type, plug, opts)

    error_message = case plug_type do
      :module   -> "expected #{inspect plug}.call/2 to return a #{pluggableMod}"
      :function -> "expected #{plug}/2 to return a #{pluggableMod}"
    end

    quote do
      #interesting but not sure about perf
      pluggable = unquote(compile_guards(call, guards))
      if !Pluggable.impl_for(pluggable) do
        IO.inspect(pluggable)
        raise unquote(error_message)
      end
      if Pluggable.halted?(pluggable) do
        pluggable
      else
        unquote(acc)
      end

      #original way, but assumes halted key in pluggable
      # case unquote(compile_guards(call, guards)) do
      #   %unquote(pluggableMod){halted: true} = pluggable ->
      #     unquote(log_halt(plug_type, plug, env, builder_opts))
      #     pluggable
      #   %unquote(pluggableMod){} = pluggable ->
      #     unquote(acc)
      #   _ ->
      #     raise unquote(error_message)
      # end
    end
  end

  defp quote_plug_call(:function, plug, opts) do
    quote do: unquote(plug)(pluggable, unquote(Macro.escape(opts)))
  end

  defp quote_plug_call(:module, plug, opts) do
    quote do: unquote(plug).call(pluggable, unquote(Macro.escape(opts)))
  end

  defp compile_guards(call, true) do
    call
  end

  defp compile_guards(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> pluggable
      end
    end
  end

  defp log_halt(plug_type, plug, env, builder_opts) do
    if level = builder_opts[:log_on_halt] do
      message = case plug_type do
        :module   -> "#{inspect env.module} halted in #{inspect plug}.call/2"
        :function -> "#{inspect env.module} halted in #{inspect plug}/2"
      end

      quote do
        require Logger
        # Matching, to make Dialyzer happy on code executing Plug.Builder.compile/3
        _ = Logger.unquote(level)(unquote(message))
      end
    else
      nil
    end
  end
end
