defmodule ExDash.Formatter.Injector.Callback do
  @moduledoc """
  An Injector for identifying Elixir type specs and injecting Callback anchors into ExDoc-generated files.

  """

  alias Floki
  alias ExDash.Formatter.Injector

  @behaviour Injector


  @doc """
  find_ids/1 returns all Elixir callbacks found in the passed HTML.

  """
  @spec find_ids(Injector.html_content) :: [Injector.id]
  def find_ids(html_content) do
    list_selector =
      ".details-list#callbacks .detail"

    id_parser =
      &Floki.attribute(&1, "id")

    Injector.find_ids_in_list(html_content, list_selector, id_parser)
    |> Enum.map(&String.replace(&1, "c:", ""))
  end


  @doc """
  match_and_anchor/1 returns a matching string and injectable anchor string for the passed id.

  """
  @spec match_and_anchor(Injector.id) :: {match :: String.t, replacement :: String.t}
  def match_and_anchor(id) do
    escaped_id =
      id |> URI.encode_www_form()

    match_string =
      "<a href=\"#c:#{id}\" class=\"detail-link\""

    dash_anchor_label =
      "Callback"

    replacement_string = """
      <a name="//apple_ref/#{dash_anchor_label}/#{escaped_id}" class="dashAnchor"></a>
      #{match_string}
    """

    {match_string, replacement_string}
  end


end
