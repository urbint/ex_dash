defmodule Mix.Tasks.Docs.Dash do
  @moduledoc """
  Run ExDoc with a Dash Docs compatible formatter and output.
  """

  use Mix.Task

  alias Mix.Tasks.Docs

  @recursive true

  @doc false
  def run(_args \\ []) do
    Docs.run(["-f", ExDash.Formatter])
  end
end
