defmodule ExDash.Store do
  @moduledoc """
  A GenServer for storing in-memory config details that
  couldn't otherwise be work-arounded.

  """

  use GenServer

  ## GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  ### Public

  @type key :: atom
  @type value :: any

  @spec get(key) :: value
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @spec set(key, value) :: any
  def set(key, value) do
    GenServer.cast(__MODULE__, {:set, key, value})
  end

  ### Callbacks

  def handle_call({:get, key}, _from, state) do
    val =
      Map.get(state, key)

    {:reply, val, state}
  end

  def handle_cast({:set, key, val}, state) do
    updated_state =
      Map.put(state, key, val)

    {:noreply, updated_state}
  end
end
