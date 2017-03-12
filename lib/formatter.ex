defmodule ExDash.Formatter do
  @moduledoc """
  An ExDoc formatter for Dash Documentation.

  """

  alias ExDash.SQLite
  alias ExDash.Formatter.Injector
  alias ExDoc.Formatter.HTML.Autolink

  @spec run(list, ExDoc.Config.t) :: String.t
  def run(project_nodes, config) when is_map(config) do
    {config, formatter_opts} = init_docset(config)

    database = formatter_opts[:docset_sqlitepath]

    SQLite.create_index(database)

    linked = Autolink.all(project_nodes, ".html", config.deps)
    nodes_map = %{
      modules: filter_list(:modules, linked),
      exceptions: filter_list(:exceptions, linked),
      protocols: filter_list(:protocols, linked)
    }

    index_nodes(nodes_map, database)

    generate_extras(config.output, config, database, linked)

    content =
      info_plist_content(config)

    "#{config.output}/../../Info.plist" |> log |> File.write(content)

    ExDoc.Formatter.HTML.run(project_nodes, config)

    output_dir =
      config.output

    File.ls!(output_dir)
    |> Stream.filter(&String.ends_with?(&1, ".html"))
    |> Stream.map(&Path.join(output_dir, &1))
    |> Enum.map(&Injector.inject_all/1)

    formatter_opts[:docset_root]
  end

  defp log(path) do
    cwd = File.cwd!
    Mix.shell.info [:green, "* creating ", :reset, Path.relative_to(path, cwd)]
    path
  end

  def filter_list(:modules, nodes) do
    Enum.filter nodes, &(not &1.type in [:exception, :protocol, :impl])
  end

  def filter_list(:exceptions, nodes) do
    Enum.filter nodes, &(&1.type in [:exception])
  end

  def filter_list(:protocols, nodes) do
    Enum.filter nodes, &(&1.type in [:protocol])
  end

  defp init_docset(config) do
    output = Path.expand(config.output)

    docset_filename = "#{config.project} #{config.version}.docset"
    docset_root = Path.join(output, docset_filename)
    docset_docpath = Path.join(docset_root, "/Contents/Resources/Documents")
    docset_sqlitepath = Path.join(docset_root, "/Contents/Resources/docSet.dsidx")

    {:ok, _} = File.rm_rf(docset_root)
    :ok = File.mkdir_p(docset_docpath)

    formatter_opts =
      [
        docset_docpath: docset_docpath,
        docset_root: docset_root,
        docset_sqlitepath: docset_sqlitepath
      ]

    config =
      %{config | output: docset_docpath}

    {config, formatter_opts}
  end

  defp index_nodes(nodes_map, database) do
    nodes_map
    |> Enum.each(fn {_key, nodes} ->
      nodes |> Enum.each(&index_node(&1, database))
    end)
  end

  defp index_node(node, database) do
    database
    |> SQLite.index_item(node.id, "Module", "#{node.id}.html")

    node.docs
    |> Enum.each(&index_list(&1, node.id, database))

    node.typespecs
    |> Enum.each(&index_list(&1, node.id, database))
  end

  defp index_list(%ExDoc.FunctionNode{} = node, module, database) do
    type =
      case node.type do
        :def -> "Function"
        :defmacro -> "Macro"
        :defcallback -> "Callback"
        _ -> "Record"
      end

    database
    |> SQLite.index_item("#{module}.#{node.id}", type, "#{module}.html##{node.id}")
  end

  defp index_list(%ExDoc.TypeNode{} = node, module, database) do
    database
    |> SQLite.index_item("#{module}.#{node.id}", "Type", "#{module}.html##{node.id}")
  end

  defp index_list(%ExDoc.ModuleNode{type: :exception} = node, _module, database) do
    database
    |> SQLite.index_item(node.id, "Exception", "#{node.id}.html")
  end

  defp generate_extras(output, config, database, modules) do
    generate_extras(output, config, database, modules, config.extras || [])
  end

  defp generate_extras(_output, _config, database, _modules, []), do: :ok
  defp generate_extras(output, config, database, modules, [file|rest]) do
    extra_path = Path.join(config.source_root, file)
    output_file = "#{Path.rootname(Path.basename(file))}.html"
    database |> SQLite.index_item(Path.basename(output_file, ".html"), "Guide", output_file)
    generate_extras(output, config, modules, rest)
  end

  @info_plist_template """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key> <string>{{CONFIG_PROJECT}}-{{CONFIG_VERSION}}</string>
	<key>CFBundleName</key> <string>{{CONFIG_PROJECT}} {{CONFIG_VERSION}}</string>
	<key>DocSetPlatformFamily</key> <string>{{CONFIG_PROJECT}}</string>
	<key>isDashDocset</key> <true/>
	<key>isJavaScriptEnabled</key> <true/>
	<key>dashIndexFilePath</key> <string>index.html</string>
	<key>DashDocSetFamily</key> <string>dashtoc</string>
</dict>
</plist>
  """

  defp info_plist_content(config) do
    @info_plist_template
    |> String.replace("{{CONFIG_PROJECT}}", config.project)
    |> String.replace("{{CONFIG_VERSION}}", config.version)
  end



end
