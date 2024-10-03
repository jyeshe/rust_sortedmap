defmodule RustSortedMap do
  use Rustler, otp_app: :rust_sortedmap, crate: :nif_btreemap

  def new(), do: error()
  def insert(_res, _a, _b), do: error()
  def get(_res, _a), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
