defmodule ExDash.Formatter do
  @moduledoc """
  An ExDoc formatter for Dash Documentation.

  """

  alias ExDash.SQLite
  alias ExDoc.Formatter.HTML.Autolink

  @ex_doc_html_match_and_replace [
    {
      "<section class=\"content\"",
      "<section class=\"content\" style=\"padding-left: 0\""
    }, {
      "<button class=\"sidebar-toggle\">",
      "<button class=\"sidebar-toggle\" style=\"visibility: hidden\">"
    }, {
      "<section class=\"sidebar\"",
      "<section class=\"sidebar\" style=\"visibility: hidden\""
    }, {
      "<div id=\"content\" class=\"content-inner\">",
      "<div id=\"content\" class=\"content-inner\" style=\"margin: 0; padding: 3px 10px\">"
    }
  ]

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
    html_content =
      File.read!(filename)

    updated_html_content =
      [:function, :type]
      |> Enum.reduce(html_content, fn id, html_content ->
        inject_anchors(html_content, id)
      end)
      |> perform_obscene_html_regex_replace(@ex_doc_html_match_and_replace)

    File.write(filename, updated_html_content)
  end

  defp perform_obscene_html_regex_replace(html_content, match_and_replace) do
    match_and_replace
    |> Enum.reduce(html_content, fn {match, replace}, html_content ->
      String.replace(html_content, match, replace)
    end)
  end

  defp inject_anchors(html_content, dash_type) do
    find_ids(dash_type, html_content)
    |> Enum.map(&anchor_and_injection(dash_type, &1))
    |> Enum.reduce(html_content, fn
      {anchor, injection}, html_content ->
        html_content |> String.replace(anchor, injection)
    end)
  end

  defp find_ids(dash_type, html_content) do
    list_selector =
      case dash_type do
        :function -> ".details-list#functions .detail"
        :type -> ".types-list .detail"
        :callback -> ".types-list .detail"
        :macro -> ".types-list .detail"
      end

    id_parser =
      case dash_type do
        :function -> &Floki.attribute(&1, "id")
        :type -> &Floki.attribute(&1, "id")
      end

    html_content
    |> Floki.find(list_selector)
    |> case do
      [] -> []
      types ->
        types |> Enum.map(&id_parser.(&1))
    end
    |> Enum.flat_map(&(&1))
  end

  defp anchor_and_injection(dash_type, id) do
    escaped_id =
      case dash_type do
        :function ->
          id |> URI.encode_www_form()
        :type ->
          id
          |> String.replace("t:", "")
          |> String.replace(~r/\/\d+$/, "")
      end

    anchor_string =
      "<a href=\"##{id}\" class=\"detail-link\""

    dash_anchor_label =
      case dash_type do
        :function -> "Function"
        :type -> "Type"
      end

    inject = """
      <a name="//apple_ref/cpp/#{dash_anchor_label}/#{escaped_id}" class="dashAnchor"></a>
      #{anchor_string}
    """

    {anchor_string, inject}
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
