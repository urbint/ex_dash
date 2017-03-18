defmodule ExDash.Formatter.Injector do
  @moduledoc """
  Injector sets Dash Anchors and makes style tweaks to passed ExDoc HTML files.

  Dash Anchors are used within Dash to build the Table of Contents per page.

  Currently supported:

    - Types
    - Functions
    - Macros
    - Callbacks

  Style tweaks include hiding the sidebar and padding tweaks to match Dash's Hex Doc styles.

  """

  alias Floki
  alias ExDash.Formatter.Injector.{Type,Function,Callback,Macro}

  @type doc_path :: String.t
  @type id :: String.t
  @type html_content :: String.t

  @dash_anchor_injectors [Type, Function, Callback, Macro]

  # Injector callbacks
  @callback find_ids(html_content) :: [id]
  @callback match_and_anchor(id) :: [{String.t, String.t}]


  @doc """
  inject_all/1 takes a path to an html file and runs some injections over it.

  The updated html is then re-written to the same path.

  """
  @spec inject_all(doc_path) :: none
  def inject_all(doc_path) do
    updated_content =
      doc_path
      |> File.read!()
      |> inject_dash_anchors()
      |> inject_style_tweaks()

    File.write!(doc_path, updated_content)
  end

  @spec inject_dash_anchors(html_content) :: html_content
  defp inject_dash_anchors(html_content, dash_anchor_injectors \\ @dash_anchor_injectors) do
    dash_anchor_injectors
    |> Enum.reduce(html_content, fn injector, html_content ->
      meta_type_ids =
        injector.find_ids(html_content)

      match_and_anchors =
        meta_type_ids
        |> Enum.map(&injector.match_and_anchor/1)

      find_and_replace_in_html(html_content, match_and_anchors)
    end)
  end

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

  @spec inject_style_tweaks(html_content) :: html_content
  defp inject_style_tweaks(html_content) do
    find_and_replace_in_html(html_content, @ex_doc_html_match_and_replace)
  end

  @spec find_and_replace_in_html(html_content, [{match :: String.t, replacement :: String.t}]) :: html_content
  defp find_and_replace_in_html(html_content, matches_and_replacements) do
    matches_and_replacements
    |> Enum.reduce(html_content, fn {match, replace}, html_content ->
      String.replace(html_content, match, replace)
    end)
  end


  @doc """
  Returns a list of ids for the given selector and parse function.

  """
  @spec find_ids_in_list(html_content, String.t, ((html_content) -> String.t)) :: [id]
  def find_ids_in_list(html_content, list_selector, id_parser) do
    html_content
    |> Floki.find(list_selector)
    |> case do
      [] -> []
      types ->
        types |> Enum.map(&id_parser.(&1))
    end
    |> Enum.flat_map(&(&1))
  end

end
