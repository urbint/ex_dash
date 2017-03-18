# ExDash

ExDash seamlessly integrates the docs in your local elixir projects with your Dash docs.

ExDash provides a mix task that rebuilds a Dash Docset for your local Elixir project.

```bash
# rebuild a basic elixir app
mix docs.dash

# rebuild an umbrella app
mix do docs.dash
```

## The Dream

The [Alfred](https://www.alfredapp.com/) + [Dash](https://kapeli.com/dash) integration for fast doc searching has become an integral part of our workflow at [Urbint](https://github.com/urbint).

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

## Usage

ExDash currently provides a mix task that rebuilds the docset for your local app.

```
mix docs.dash
```

In an umbrella app, you'll need to provide a command to run it in all the sub apps.

```
mix do docs.dash
TODO: auto-magically handle umbrella apps with same command
```

From there, you can open that docset on your machine to refresh the Dash contents.

- TODO: flag for auto-opening
- TODO: flag for auto-moving it into the proper Dash folder if it exists already

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
  - `dashAnchors` injected into the docs pages, to populate the table of contents along the left side of Dash's view

These are run in succession in `ExDash.Formatter`.
See `ExDash.Formatter.Docset` and `ExDash.Formatter.Injector` for more.

