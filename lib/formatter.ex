defmodule ExDash.Formatter do
  @moduledoc """
  An ExDoc formatter for Dash Documentation.

  """

  alias ExDash.SQLite
  alias ExDoc.Formatter.HTML.Autolink

  @spec run(list, ExDoc.Config.t) :: String.t
  def run(project_nodes, config) when is_map(config) do
    {config, formatter_opts} = init_docset(config)

    database = formatter_opts[:docset_sqlitepath]

    SQLite.create_index(database)

    # TODO generate assets
    # TODO generate icon

    linked = Autolink.all(project_nodes, ".html", config.deps)
    nodes_map = %{
      modules: filter_list(:modules, linked),
      exceptions: filter_list(:exceptions, linked),
      protocols: filter_list(:protocols, linked)
    }

    index_nodes(nodes_map, database)

    generate_extras(config.output, config, database, linked)

    # generate sql data for overview

    content =
      info_plist_content(config)

    "#{config.output}/../../Info.plist" |> log |> File.write(content)

    ExDoc.Formatter.HTML.run(project_nodes, config)

    inject_dash_anchors(config.output)
    # close sidebars

    formatter_opts[:docset_root]
  end

  defp inject_dash_anchors(output_dir) do
    File.ls!(output_dir)
    |> Stream.filter(&String.ends_with?(&1, ".html"))
    |> Stream.map(&Path.join(output_dir, &1))
    |> Enum.map(&inject_dash_anchors_for_file/1)
  end

  defp inject_dash_anchors_for_file(filename) do
    injected =
      File.read!(filename)
      |> inject_anchors()

    File.write(filename, injected)
  end

  defp inject_anchors(html_content) do
    type_ids =
      find_type_ids(html_content)

    function_ids =
      find_function_ids(html_content)

    macro_ids =
      find_macro_ids(html_content)

    callback_ids =
      find_callback_ids(html_content)

    html_content
    |> inject_type_anchors(type_ids)
    |> inject_function_anchors(function_ids)
    |> inject_callback_anchors(callback_ids)
    |> inject_macro_anchors(macro_ids)
  end

  defp find_function_ids(html_content) do
    html_content
    |> Floki.find(".details-list#functions .detail")
    |> case do
      [] ->
        []
      types ->
        types
        |> Enum.map(&Floki.attribute(&1, "id"))
    end
    |> Enum.flat_map(&(&1))
  end

  defp inject_function_anchors(html_content, []), do: html_content
  defp inject_function_anchors(html_content, [function_id | rest] = _function_ids) do
    function_name =
      type_id
      |> String.replace("t:", "")
      |> String.replace(~r/\/\d+$/, "")

    anchor_string =
      "<a href=\"##{type_id}\""

    inject = """
      <a name="//apple_ref/cpp/Type/#{type}" class="dashAnchor"></a>
      #{anchor_string}
    """

    updated_html_content =
      html_content
      |> String.replace(anchor_string, inject)

    inject_type_anchors(updated_html_content, rest)
  end

  defp find_callback_ids(html_content) do
    html_content
  end

  defp inject_callback_anchors(html_content, []), do: html_content
  defp inject_callback_anchors(html_content, [callback_id | rest] = _callback_ids) do
    html_content
  end

  defp find_macro_ids(html_content) do
    html_content
  end

  defp inject_macro_anchors(html_content, []), do: html_content
  defp inject_macro_anchors(html_content, [macro_id | rest] = _macro_ids) do
    html_content
  end

  defp inject_type_anchors(html_content, []), do: html_content
  defp inject_type_anchors(html_content, [type_id | rest] = _type_ids) do
    type =
      type_id
      |> String.replace("t:", "")
      |> String.replace(~r/\/\d+$/, "")

    anchor_string =
      "<a href=\"##{type_id}\""

    inject = """
      <a name="//apple_ref/cpp/Type/#{type}" class="dashAnchor"></a>
      #{anchor_string}
    """

    updated_html_content =
      html_content
      |> String.replace(anchor_string, inject)

    inject_type_anchors(updated_html_content, rest)
  end

  defp find_type_ids(html_content) do
    html_content
    |> Floki.find(".types-list .detail")
    |> case do
      [] ->
        []
      types ->
        types
        |> Enum.map(&Floki.attribute(&1, "id"))
    end
    |> Enum.flat_map(&(&1))
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
      |> IO.inspect(label: :node_type)

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
