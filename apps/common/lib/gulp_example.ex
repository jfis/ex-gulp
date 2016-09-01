defmodule ModuleGulp do
  @behaviour Gulp

  def init(_opts) do
    [new: "new"]
  end

  def call(conn, opts) do
    IO.puts "module gulp"
    IO.inspect(conn)
    IO.inspect(opts)

    # Gulp.Conn.run_response_handlers(conn)
    conn
  end
end

defmodule GulpClient do
  use Gulp.Builder
  import Gulp.Conn

  # pipeline :sandbox do
    plug Gulp.RequestId, key: "Request-Id", func: &__MODULE__.test/0
    plug :private_gulp, %{test: "eats"}
    plug :on_response
    plug :public_gulp, 4
    plug Gulp.Adapter.Hackney#this module shouldnt know adapter, but how to set placement?
    plug ModuleGulp, key: :yes
  # end

  def action1(param1, _param2, _param3) do
    post "/path1/path2", body: param1
  end

  def action2(param) do
    post "/path1/path2", body: param
  end

  defp private_gulp(conn, opts) do
    IO.puts "private gulp"
    IO.inspect(conn)
    IO.inspect(opts)
    conn
  end

  defp on_response(conn, opts) do
    IO.puts "on response"
    conn
    |> register_response_handler( &(rh(&1)) )
  end

  defp rh(conn) do
    IO.puts "rh"
    conn
  end

  def public_gulp(conn, opts) do
    IO.puts "public gulp"
    IO.inspect(conn)
    IO.inspect(opts)
    conn
  end

  def test(), do: "eaeaetasentas"
end
