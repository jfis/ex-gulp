defmodule ModuleGulp2 do
  @behaviour Gulp

  def init(_opts) do
    [new: "new2"]
  end

  def call(conn, opts) do
    IO.puts "module gulp2"
    IO.inspect opts
    conn
  end
end

defmodule ModuleGulp do
  @behaviour Gulp
  # use Gulp.Builder

  # plug ModuleGulp2

  def init(_opts) do
    [new: "new"]
  end

  def call(conn, _opts) do
    IO.puts "module gulp"
    conn
    # super(conn, opts)
  end
end

defmodule GulpClient do
  use Gulp.Builder

  plug :before do
    plug Gulp.RequestId, key: "Request-Id", func: &__MODULE__.test/0
    plug :private_gulp, %{test: "eats"}
    plug :on_response
    plug :public_gulp, 4
  end

  plug :after do
    plug ModuleGulp, key: :yes
    plug :nested do
      plug :public_gulp, 5
      plug :nested do
        plug :public_gulp, 7
      end
    end
    plug :public_gulp, 6
  end


  plug :before
  plug Gulp.Adapter.Hackney #this module maybe shouldnt know adapter, but how to set placement?
  plug :after


  plug :alt do
    plug :before
    # plug Gulp.Adapter.Hackney #this module maybe shouldnt know adapter, but how to set placement?
    plug :after
  end

  import Gulp.Conn

  def normal() do
    post "/path1/path2", body: "param1"
  end

  def direct_pipeline() do
    # pipe_through :alt

    post :alt, "/path1/path2", body: "param1", x: 111
  end

  defp private_gulp(conn, opts) do
    IO.puts "private gulp"
    IO.inspect(conn)
    IO.inspect(opts)
    conn
  end

  defp on_response(conn, _opts) do
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
