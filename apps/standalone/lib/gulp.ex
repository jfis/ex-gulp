defmodule Gulp do
  @moduledoc """
  """
  @type opts :: tuple | atom | integer | float | [opts]

  @callback init(opts) :: opts
  @callback call(Gulp.Conn.t, opts) :: Gulp.Conn.t

end
