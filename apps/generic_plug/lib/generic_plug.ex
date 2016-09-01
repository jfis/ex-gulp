defmodule GenericPlug do
  @moduledoc """
  """
#
  defmacro __using__(_opts) do
    quote do
      @type opts :: tuple | atom | integer | float | [opts]

      @callback init(opts) :: opts
      @callback call(Pluggable.t, opts) :: Pluggable.t
    end
  end
end
