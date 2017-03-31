defmodule Mix.Tasks.Docs.Dash do
  @moduledoc """
  Run ExDoc with a Dash Docs compatible formatter and output.
  """

  use Mix.Task

  alias Mix.Tasks.Docs

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

    [{project_nodes, config}] =
      Docs.run(["-f", ExDash])

    name =
      Keyword.get(opts, :name, "ExDash Generated Docset")

    config =
      if config.project == "" or not(is_nil(name)) do
        %{config | project: name}
      else
        config
      end

    doc_set_path =
      ExDash.build_docs(project_nodes, config)

    auto_open? =
      Keyword.get(opts, :open, false)

    if auto_open? do
      IO.inspect(doc_set_path, label: :opening)
      System.cmd("open", [doc_set_path], [])
    end

    doc_set_path
  end
end
