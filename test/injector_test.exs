defmodule ExDash.InjectorTest do
  use ExUnit.Case

  alias ExDash.Injector.{Type,Function,Callback,Macro}

  @escaped_html_page "./test/formatter/page_with_callbacks.html" |> Path.expand()

  setup_all do
    content =
      File.read!(@escaped_html_page)

    type_ids =
      ["doc_path/0", "html_content/0", "id/0"]

    function_ids =
      ["find_ids_in_list/3", "inject_all/1"]

    callback_ids =
      ["find_ids/1", "match_and_anchor/1"]

    macro_ids =
      ["scopes/1"]

    {:ok, content: content,
     type_ids: type_ids,
     function_ids: function_ids,
     callback_ids: callback_ids,
     macro_ids: macro_ids,
    }
  end

  describe "Type Injector" do
    test "fetches type ids", %{content: content, type_ids: type_ids} do
      ids =
        Type.find_ids(content)

      assert ids == type_ids
    end

    test "builds matches and replacements", %{content: content, type_ids: [type_id | _rest]} do
      {match, replacement} =
        Type.match_and_anchor(type_id)

      assert match == "<a href=\"#t:doc_path/0\" class=\"detail-link\""
      assert replacement == "  <a name=\"//apple_ref/Type/doc_path\" class=\"dashAnchor\"></a>\n  <a href=\"#t:doc_path/0\" class=\"detail-link\"\n"
    end
  end

  describe "Function Injector" do
    test "fetches function ids", %{content: content, function_ids: function_ids} do
      ids =
        Function.find_ids(content)

      assert ids == function_ids
    end

    test "builds matches and replacements", %{content: content, function_ids: [function_id | _rest]} do
      {match, replacement} =
        Function.match_and_anchor(function_id)

      assert match == "<a href=\"#find_ids_in_list/3\" class=\"detail-link\""
      assert replacement == "  <a name=\"//apple_ref/Function/find_ids_in_list%2F3\" class=\"dashAnchor\"></a>\n  <a href=\"#find_ids_in_list/3\" class=\"detail-link\"\n"
    end
  end

  describe "Callback Injector" do
    test "fetches callback ids", %{content: content, callback_ids: callback_ids} do
      ids =
        Callback.find_ids(content)

      assert ids == callback_ids
    end

    test "builds matches and replacements", %{callback_ids: [callback_id | _rest]} do
      {match, replacement} =
        Callback.match_and_anchor(callback_id)

      assert match == "<a href=\"#c:find_ids/1\" class=\"detail-link\""
      assert replacement == "  <a name=\"//apple_ref/Callback/find_ids%2F1\" class=\"dashAnchor\"></a>\n  <a href=\"#c:find_ids/1\" class=\"detail-link\"\n"
    end
  end

  describe "Macro Injector" do
    test "fetches macro ids", %{content: content, macro_ids: macro_ids} do
      ids =
        Macro.find_ids(content)

      assert ids == macro_ids
    end

    test "builds matches and replacements", %{macro_ids: [macro_id | _rest]} do
      {match, replacement} =
        Macro.match_and_anchor(macro_id)

      assert match == "<a href=\"#scopes/1\" class=\"detail-link\""
      assert replacement == "  <a name=\"//apple_ref/Macro/scopes%2F1\" class=\"dashAnchor\"></a>\n  <a href=\"#scopes/1\" class=\"detail-link\"\n"
    end
  end
end
