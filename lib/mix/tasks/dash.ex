defmodule Mix.Tasks.Docs.Dash do
  @moduledoc """
  Run ExDoc with a Dash Docs compatible formatter and output.
  """

  use Mix.Task

  alias Mix.Tasks.Docs

  @auto_open_flags ["--open", "-o"]

  @type args :: [String.t]

  @doc """
  Builds a Dash Docset for the current Mix project.

  Call with `--open` or `-o` to open in Dash following the build.

  """
  @spec run(args) :: String.t
  def run(args \\ []) do
    [doc_set_path] =
      Docs.run(["-f", ExDash.)

    auto_open? =
      Enum.any?(args, &(&1 in @auto_open_flags))

    if auto_open? do
      IO.inspect(doc_set_path, label: :opening)
      System.cmd("open", [doc_set_path], [])
    end

    doc_set_path
  end
end
