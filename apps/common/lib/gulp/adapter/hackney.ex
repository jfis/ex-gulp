defmodule Gulp.Adapter.Hackney do

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    # case Gulp.Adapter.call(%Gulp.Conn{}, opts) do
    # case :hackney.request() do
    #   {:ok, _status, _headers, ref} = resp ->
    #     IO.inspect resp
    #     {:ok, body} = :hackney.body(ref)
    #     # Logger.debug body
    #     {:ok}
    #   r ->
    #     IO.inspect r
    #     raise "debit failed"
    # end
    %{conn | resp_body: "response body"}
  end
end
