defmodule ModulePlug do
  @behaviour Plug

  def init(_opts) do
    [new: "new"]
  end

  def call(conn, opts) do
    IO.puts "module gulp"
    IO.inspect(conn)
    IO.inspect(opts)
    conn
  end
end

defmodule PlugClient do
  use Plug.Builder

  # # gulpline :qb do
  plug :private_gulp, %{test: "eats"}
  plug :bad
  plug :halt
  plug :public_gulp, 4
  plug ModulePlug, poop: :yes
  # # end
  #
  def action1() do
    %Plug.Conn{halted: false}
    |> call([])
  end

  #
  defp bad(_conn, _opts) do
    2
  end
  defp halt(conn, _opts) do
    %{conn | halted: true}
  end

  defp private_gulp(conn, opts) do
    IO.puts "private gulp"
    IO.inspect(conn)
    IO.inspect(opts)
    conn
  end
  #
  def public_gulp(conn, opts) do
    IO.puts "public gulp"
    IO.inspect(conn)
    IO.inspect(opts)
    conn
  end

  def test(), do: "eaeaetasentas"
end
