defmodule Plug do
  use GenericPlug
end

defmodule Plug.Conn do
  defstruct halted: false
end

defmodule Plug.Builder do
  defmacro __using__(_opts) do
    quote do
      use GenericPlug.Builder, pluggable: Plug.Conn, behaviour: Plug 
    end
  end
end

defimpl Pluggable, for: Plug.Conn do
  def halted?(%Plug.Conn{halted: true}), do: true
  def halted?(_), do: false
end
