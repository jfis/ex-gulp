defmodule Gulp.Oauth do
  @behaviour Gulp
  alias Gulp.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    creds = conn.assigns.oauth
    header = make_oauth_header(creds, conn.url, conn.method)

    %Conn{conn |
      req_headers: [header | conn.req_headers]
    }
  end

  defp make_oauth_header(creds, url, method) do
    params = Oauth.sign(method, url, [],
      creds.consumer_key, creds.consumer_secret,
      creds.access_token, creds.access_token_secret)
    {header, _} = Oauth.as_header(params)
    header
  end
end
