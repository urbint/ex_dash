# ExDash

ExDash seamlessly integrates the docs in your local elixir projects with your Dash docs.

ExDash provides a mix task that rebuilds a Dash Docset for your local Elixir project.

You can read more about the intended doc-searching workflow [in this blog post](https://medium.com/@russmatney/exdash-internal-elixir-docs-integrated-with-dash-434245fc8023).


### Quick Start

1. Add `{:ex_dash, "~> 0.1", only: :dev},` to your mix.exs deps
1. Run `mix docs.dash`
1. Viola! Your docs are now searchable in [Dash](https://kapeli.com/dash)


## The Dream

The [Alfred](https://www.alfredapp.com/) + [Dash](https://kapeli.com/dash) integration
for fast Elixir doc searching has become an integral part of our workflow at [Urbint](https://github.com/urbint).

Once our app reached a certain size,
we wanted to be able to search our internal documentation as easily as the public Hex docs.

Being able to dogfood our own @moduledocs and function @docs helps us keep code quality higher.

ExDash is intended to make that easier.

## Installation

The package can be installed
by adding `ex_dash` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_dash, "~> 0.1.0"},
  ]
end
```

### Dependencies

Dash Docsets include a SQLite table, and as such,
this task expects `sqlite3` to be available.

```
brew install sqlite3
```

## Usage

ExDash currently provides a mix task that rebuilds the docset for your local app.

```
mix docs.dash
```

If the docset is being built for the first time,
this command will finish by opening the docset via Dash.
If the docset already exists locally,
this command will assume that you are updating your local docs.

Options:

- `--open`: force the generated docset to open in dash
- `--name`: Overwrite the project name when naming the docset.
  The name defaults to the project name, or for umbrella apps,
  the name of the directory.

# Hacking ExDocs into Dash Docs

The goal for this project is to provide documentation for your local app
to the same resource as the rest of your Docs.
We want the docs to be indistinguishable from Elixir's source and Hex's docsets.

As such, this task builds the full docs using ExDoc,
then scrapes and find/replaces those pages into a similar (hopefully identical) style to those downloaded from Hex.

Dash docsets require:

  - a SQLite database for search
  - Dash "anchors" on the doc pages to populate the Table of Contents per page

See `ExDash.Docset` and `ExDash.Injector` for more.

If there are other Dash features you'd like supported,
please open a PR or an Issue!

# Much thanks to the Elixir Community

This project at the start borrowed heavily from work done [by @JonGretar on ExDocDash](https://github.com/JonGretar/ExDocDash). Much thanks to Jon's code as well as [ExDoc](https://github.com/elixir-lang/ex_doc), as they both made this problem much easier to solve. A break from Jon's project was made in favor of matching the style of documents built by ExDoc. Rather than writing and styling our own templates, this just builds the ExDoc docs and hacks them into a Docset.
