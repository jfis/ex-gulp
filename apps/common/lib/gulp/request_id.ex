defmodule Gulp.RequestId do
  @behaviour Gulp

  alias Gulp.Conn

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    IO.inspect "rid"
    IO.inspect opts
    value = Keyword.get(opts, :func).()
    IO.inspect value
    header = [{Keyword.get(opts, :key), value}]
    # # conn
    # # |> add_header(header)
    %Conn{conn | req_headers: header ++ conn.req_headers}
    # conn
  end

end
