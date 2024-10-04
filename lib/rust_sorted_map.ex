defmodule RustSortedMap do
  use Rustler, otp_app: :rust_sortedmap, crate: :nif_btreemap

  def new(), do: error()
  def insert(_res, _key, _val), do: error()
  def get(_res, _key), do: error()
  def prev(_res, _key), do: error()
  def prev(_res, _key, _count), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
