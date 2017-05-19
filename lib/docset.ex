defmodule ExDash.Docset do
  @moduledoc """
  Responsible for building the structure, SQLite DB, and Info.plist of a Dash Docset.

  """

  alias ExDash.Docset.SQLite
  alias ExDoc.Formatter.HTML.Autolink
  alias ExDash.Store

  @doc """
  build/2 converts a list of project nodes and a config into a Dash Docset,
  and writes that docset to your `/doc` dir.

    * takes a list of project_nodes and a config
    * initializes the directory structure and SQLite DB
    * iterates over the project nodes while writes metadata to the DB
    * writes content to the Info.plist

  """
  @spec build(list, ExDoc.Config.t) :: {config :: ExDoc.Config.t, docset_path :: String.t}
  def build(project_nodes, config) do
    {docset_docpath, database_path, docset_root_path} =
      init_docset(config)

    config =
      %{config | output: docset_docpath}

    build_sqlite_db(project_nodes, config, database_path)

    write_plist(config)

    {config, docset_root_path}
  end

  defp init_docset(config) do
    output = Path.expand(config.output)

    docset_filename =
      case config.version do
        "dev" ->
          "#{config.project}.docset"
        version ->
          "#{config.project} #{version}.docset"
      end

    docset_root = Path.join(output, docset_filename)
    docset_docpath = Path.join(docset_root, "/Contents/Resources/Documents")
    docset_sqlitepath = Path.join(docset_root, "/Contents/Resources/docSet.dsidx")

    is_new_docset? =
      not(File.exists?(docset_root))

    Store.set(:is_new_docset, is_new_docset?)

    {:ok, _} = File.rm_rf(docset_root)
    :ok = File.mkdir_p(docset_docpath)

    {docset_docpath, docset_sqlitepath, docset_root}
  end

  defp build_sqlite_db(project_nodes, config, database_path) do
    SQLite.create_index(database_path)

    Autolink.all(project_nodes, ".html", config.deps)
    |> Enum.map(&index_node(&1, database_path))
  end

  defp index_node(node, database) do
    database
    |> SQLite.index_item(node.id, "Module", "#{node.id}.html")

    node.docs
    |> Enum.each(&index_sub_node(&1, node.id, database))

    node.typespecs
    |> Enum.each(&index_sub_node(&1, node.id, database))
  end

  defp index_sub_node(%ExDoc.FunctionNode{} = node, module, database) do
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

  defp index_sub_node(%ExDoc.TypeNode{} = node, module, database) do
    database
    |> SQLite.index_item("#{module}.#{node.id}", "Type", "#{module}.html##{node.id}")
  end

  defp index_sub_node(%ExDoc.ModuleNode{type: :exception} = node, _module, database) do
    database
    |> SQLite.index_item(node.id, "Exception", "#{node.id}.html")
  end

  defp log(path) do
    cwd = File.cwd!
    Mix.shell.info [:green, "* creating ", :reset, Path.relative_to(path, cwd)]
    path
  end

  defp write_plist(config) do
    content =
      info_plist_content(config)

    "#{config.output}/../../Info.plist" |> log |> File.write(content)
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

  defp info_plist_content(%{project: name, version: version}) do
    version =
      case version do
        "dev" ->
          ""
        version ->
          version
      end

    @info_plist_template
    |> String.replace("{{CONFIG_PROJECT}}", name)
    |> String.replace("{{CONFIG_VERSION}}", version)
  end

end
