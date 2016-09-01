defmodule Gulp.Json do
  @behaviour Gulp
  alias Gulp.Conn

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    header = {"content-type", "application/json"}
    body = opts.json.encode!(conn.body)

    %Conn{conn |
      req_headers: [header | conn.req_headers],
      req_body: body,
    }
  end
end
