# ExDash

ExDash seamlessly integrates the docs in your local elixir projects with your Dash docs.

ExDash provides a mix task that rebuilds a Dash Docset for your local Elixir project.

```bash
mix docs.dash
```

## The Dream

The [Alfred](https://www.alfredapp.com/) + [Dash](https://kapeli.com/dash) integration
for fast doc searching has become an integral part of our workflow at [Urbint](https://github.com/urbint).

Once our app reached a certain size,
we wanted to be able to search our own internal documentation as easily as the public Hex docs.

Being able to more easily dogfood these docs would only encourage us to improve them.

ExDash is a tool for closing that gap.

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

To auto-open the docset after it is generated, you can pass `--open` to the task.

```
mix docs.dash --open
```

- TODO: flag for auto-moving it into the proper Dash folder, rather than opening it

### A git-hook, perhaps?

If you'd like, you can auto-update your docs everytime you pull the latest from github.

```
TODO write githook
```

# Under the hood

The goal was for the docs to be indistinguishable from the rest of Elixir documentation
provided via Hex and Dash.

As such, this task builds the docs using ExDoc under the hood,
and uses those pages as the source pages for showing the documentation.

Outside of that, Dash docsets rely on two things:

  - a SQLite database for search
  - Dash "anchors" injected into the docs pages, to populate the table of contents along the left side of Dash's view. Currently Functions, Types, Callbacks, and Macros are supported.

These are run in succession in `ExDash..
See `ExDash.Docset` and `ExDash.Formatter.Injector` for more.

