defmodule Mix.Tasks.Docs.DashTest do
  @moduledoc """
  Generates the dash docset for this repo,
  and inspects the ExDash.for Dash Anchors
  and an arity 2 run function.

  """

  use ExUnit.Case, async: true

  setup_all do
    doc_filename =
      "Mix.Tasks.Docs.Dash.html"

    dash_docset_path =
      Mix.Tasks.Docs.Dash.run()

    doc_filepath =
      dash_docset_path
      |> Path.join("Contents/Resources/Documents")
      |> Path.join(doc_filename)

    {:ok, docset_path: dash_docset_path, doc_filepath: doc_filepath}
  end

  describe "lib/formatter.ex" do
    test "ExDash.is part of the generated docset",
      %{doc_filepath: doc_filepath} do
      file_content =
        doc_filepath
        |> File.read!()

      assert String.contains?(file_content, "Mix.Tasks.Docs.Dash")
    end

    test "ExDash.has a Dash Anchor for its run function",
      %{doc_filepath: doc_filepath} do
      file_content =
        doc_filepath
        |> File.read!()

      dash_anchor_for_run_function =
        "<a name=\"//apple_ref/Function/run%2F1\" class=\"dashAnchor\"></a>"

      assert String.contains?(file_content, dash_anchor_for_run_function)
    end
  end
end
