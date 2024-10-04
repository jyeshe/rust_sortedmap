defmodule RustSortedMap.Worker do
  use GenServer

  def start_link(mode) do
    GenServer.start_link(__MODULE__, mode, name: __MODULE__)
  end

  @impl true
  def init(mode) do
    pid = :ets.new(:sorted_table, [:ordered_set])
    res = RustSortedMap.new()

    txs =
      Enum.map(1..20_000, fn _i ->
        json =
          Map.new(1..20, fn _j ->
            {1_000_000 + :rand.uniform(9_000_000), Enum.random(1_000_000..9_000_000)}
          end)
          |> Jason.encode!()

        {Base.encode16(:crypto.strong_rand_bytes(16)), json}
      end)

    Process.send_after(self(), {:ets_write, txs}, 5000)

    {:ok, %{table: pid, tree: res, mode: mode}}
  end

  @impl true
  def handle_info({:ets_write, txs}, %{table: pid} = state) do
    start = :erlang.monotonic_time(:millisecond)

    Enum.each(txs, fn {key, value} ->
      :ets.insert(pid, {key, value})
    end)

    elapsed = :erlang.monotonic_time(:millisecond) - start

    IO.puts("ets_write: #{elapsed}ms")
    Process.send_after(self(), {:rust_write, txs}, 5000)

    {:noreply, state}
  end

  @impl true
  def handle_info({:rust_write, txs}, %{tree: btree} = state) do
    start = :erlang.monotonic_time(:millisecond)

    Enum.each(txs, fn {key, value} ->
      RustSortedMap.insert(btree, key, value)
    end)

    elapsed = :erlang.monotonic_time(:millisecond) - start

    IO.puts("rust_write: #{elapsed}ms")
    Process.send_after(self(), :ets_read, 5000)

    {:noreply, state}
  end

  @impl true
  def handle_info(:ets_read, %{table: pid} = state) do
    query_key = :lists.duplicate(16, 64) |> :binary.list_to_bin() |> Base.encode16()
    start = :erlang.monotonic_time(:millisecond)

    txs =
      Stream.unfold(query_key, fn
        key when is_binary(key) ->
          value = :ets.lookup(pid, key)

          case :ets.prev(pid, key) do
            :"$end_of_table" ->
              {value, :none}

            prev_key ->
              {value, prev_key}
          end

        _eot ->
          nil
      end)
      |> Enum.to_list()

    elapsed = :erlang.monotonic_time(:millisecond) - start

    IO.puts("ets_read: #{elapsed}ms (#{Enum.count(txs)})")
    Process.send_after(self(), :rust_read1, 5000)

    {:noreply, state}
  end

  @impl true
  def handle_info(:rust_read1, %{tree: btree} = state) do
    query_key = :lists.duplicate(16, 64) |> :binary.list_to_bin() |> Base.encode16()
    start = :erlang.monotonic_time(:millisecond)

    first = RustSortedMap.get(btree, query_key)

    txs =
      Stream.unfold(query_key, fn
        key when is_binary(key) ->
          case RustSortedMap.prev(btree, key) do
            {prev_key, value} ->
              {value, prev_key}

            :error ->
              nil
          end

        _eot ->
          nil
      end)
      |> Enum.to_list()

    txs = [first | txs]
    elapsed = :erlang.monotonic_time(:millisecond) - start

    IO.puts("rust_read: #{elapsed}ms (#{Enum.count(txs)})")
    Process.send_after(self(), :rust_read2, 5000)

    {:noreply, state}
  end

  @impl true
  def handle_info(:rust_read2, %{tree: btree} = state) do
    query_key = :lists.duplicate(16, 64) |> :binary.list_to_bin() |> Base.encode16()
    start = :erlang.monotonic_time(:millisecond)
    list = RustSortedMap.prev(btree, query_key, 6000)
    elapsed = :erlang.monotonic_time(:millisecond) - start

    IO.puts("rust_read_count: #{elapsed}ms (#{Enum.count(list)})")
    Process.send_after(self(), :ets_read, 5000)

    {:noreply, state}
  end
end
