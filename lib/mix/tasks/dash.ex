defmodule Mix.Tasks.Docs.Dash do
  @moduledoc """
  Run ExDoc with a Dash Docs compatible formatter and output.
  """

  use Mix.Task

  alias Mix.Tasks.Docs
  alias ExDash.Store

  @type args :: [String.t]

  @doc """
  Builds a Dash Docset for the current Mix project.

  Call with `--open` to open in Dash following the build.

  Call with `--name NAME` to name the built docset.

  """
  @spec run(args) :: String.t
  def run(args \\ []) do
    {opts, _, _} =
      OptionParser.parse(args, switches: [open: :boolean, name: :string])

    name =
      Keyword.get(opts, :name, "ExDash Generated Docset")

    Store.start_link()

    Store.set(:name, name)

    [doc_set_path] =
      Docs.run(["-f", ExDash])

    auto_open? =
      Keyword.get(opts, :open, false)

    if auto_open? do
      IO.inspect(doc_set_path, label: :opening)
      System.cmd("open", [doc_set_path], [])
    end

    doc_set_path
  end
end
