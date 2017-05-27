# 0.1.6 updated ex_doc dep, test fix

# 0.1.5 Smart Defaults

The `--open` flag is now more of a 'force' open. When `mix docs.dash` is called, the docset is opened automatically, unless a docset with the exact name already exists (in that case, the docs update under the hood, but do not need to be re-opened in Dash for the updates to be realized).

The `--name NAME` param now defaults to setting umbrella project names to the result of `File.cwd!() |> Path.basename()`, as this is likely the desired project name anyway.

An `--abbr ABBR` option can be passed to set a custom abbreviation. This can also be edited in Dash's preferences pane by hand. This only works when the docset is first added to Dash - after that, it must be updated via Dash or fully removed and readded.

# 0.1.4 tweak margins to match elixir docs

# 0.1.3 fix app-name overwrite bug

# 0.1.2 `--name NAME` and Umbrella App handling

# 0.1.1 auto-open docset

Add `--open` to auto-open the generated docset.

`mix docs.dash --open`

# 0.1.0 initial release

`mix docs.dash`
