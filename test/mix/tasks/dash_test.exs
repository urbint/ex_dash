defmodule Mix.Tasks.Docs.DashTest do
  @moduledoc """
  Generates the dash docset for this repo,
  and inspects the ExDash.Formatter for Dash Anchors
  and an arity 2 run function.

  """

  use ExUnit.Case, async: true

  setup_all do
    doc_filename =
      "ExDash.Formatter.html"

    dash_docset_path =
      Mix.Tasks.Docs.Dash.run()

    doc_filepath =
      dash_docset_path
      |> Path.join("Contents/Resources/Documents")
      |> Path.join(doc_filename)

    {:ok, docset_path: dash_docset_path, doc_filepath: doc_filepath}
  end

  describe "lib/formatter.ex" do
    test "ExDash.Formatter is part of the generated docset",
      %{doc_filepath: doc_filepath} do
      file_content =
        doc_filepath
        |> File.read!()

      assert String.contains?(file_content, "ExDash.Formatter")
    end

    test "ExDash.Formatter has Dash Anchors",
      %{doc_filepath: doc_filepath} do
      file_content =
        doc_filepath
        |> File.read!()

      assert String.contains?(file_content, "dashAnchor")
    end

    test "ExDash.Formatter has a Dash Anchor for its run function",
      %{doc_filepath: doc_filepath} do
      file_content =
        doc_filepath
        |> File.read!()

      dash_anchor_for_run_function =
        "<a name=\"//apple_ref/cpp/Function/run%2F2\" class=\"dashAnchor\"></a>"

      assert String.contains?(file_content, dash_anchor_for_run_function)
    end
  end
end
