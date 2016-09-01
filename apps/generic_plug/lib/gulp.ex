defmodule Gulp do
  use GenericPlug
end

defimpl Pluggable, for: Gulp.Conn do
  def halted?(%Gulp.Conn{halted: true}), do: true
  def halted?(_), do: false
end
