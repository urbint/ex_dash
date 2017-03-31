defmodule ExDash do
  @moduledoc """
  ExDash provides a `Formatter` and mix task for converting your elixir project into a Dash docset.

  """

  alias ExDash.{Injector,Docset}

  @doc """
  A run function to be called within ExDoc.

  ExDoc Formatters typically build the docs here.
  Instead, we return the required pieces to check and override a few config settings before building the docs in build_docs/2.
  """
  @spec run(list, ExDoc.Config.t) :: {list, ExDoc.Config.t}
  def run(project_nodes, config) when is_map(config) do
    {project_nodes, config}
  end

  @spec build_docs(list, ExDoc.Config.t) :: String.t
  def build_docs(project_nodes, config) do
    {config, docset_root_path} =
      Docset.build(project_nodes, config)

    ExDoc.Formatter.HTML.run(project_nodes, config)

    transform_ex_docs_to_dash_docs(config.output)

    docset_root_path
  end

  defp transform_ex_docs_to_dash_docs(output_docs_dir, ends_with \\ ".html") do
    File.ls!(output_docs_dir)
    |> Stream.filter(&String.ends_with?(&1, ends_with))
    |> Stream.map(&Path.join(output_docs_dir, &1))
    |> Enum.map(&Injector.inject_all/1)
  end

end
