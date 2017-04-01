# ExDash

ExDash seamlessly integrates the docs in your local elixir projects with your Dash docs.

ExDash provides a mix task that rebuilds a Dash Docset for your local Elixir project.


### Quick Start

1. add `{:ex_dash, "~> 0.1", only: :dev},` to your mix.exs deps
1. run `mix docs.dash --open`
1. viola! Your docs are now searchable in [Dash!](https://kapeli.com/dash) integration!


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

Options:

- `--open`: automatically runs an "open" command after the docset is built. You
  probably don't want this command if you run ex_dash as part of an automated process (i.e. a Git hook or on file-save)
- `--name`: Overwrite the project name when naming the docset. (Recommended for Umbrella Apps)
- TODO: flag for automatically moving docs into the proper Dash folder (under-the-hood update)

# Hacking ExDocs into Dash Docs

The goal for this project is to provide documentation for your local app
to the same resource as the rest of your Docs.
We want the docs to be indistinguishable from Elixir's source and Hex's docsets.

As such, this task builds the full docs using ExDoc under the hood,
then scrapes and find/replaces those pages into a similar (hopefully identical) style to those downloaded from Hex.

Dash docsets require:

  - a SQLite database for search
  - Dash "anchors" on the doc pages to populate the Table of Contents per page

See `ExDash.Docset` and `ExDash.Injector` for more.

If there are other Dash features you'd like supported,
please open a PR or an Issue!

