defmodule ExDash.Formatter do
  @moduledoc """
  An ExDoc formatter for Dash Documentation.

  """

  alias ExDash.Formatter.{Injector,Docset}

  @spec run(list, ExDoc.Config.t) :: String.t
  def run(project_nodes, config) when is_map(config) do
    config =
      if config.project == "" do
        %{config | project: "umbrella"}
      else
        config
      end

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
