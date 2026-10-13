defmodule TimeManager.Pagination do
  @moduledoc """
  Optional `?limit=&offset=` paging for list endpoints.

  Every list is capped at `cap` rows, even without a `limit` param,
  so a single request can never dump an unbounded table.
  """
  import Ecto.Query

  def paginate(query, params, cap) do
    limit = params |> int_param("limit", cap) |> min(cap) |> max(1)
    # Bound database work and avoid bigint overflow on hostile offset values.
    offset = params |> int_param("offset", 0) |> max(0) |> min(1_000_000)

    from q in query, limit: ^limit, offset: ^offset
  end

  defp int_param(params, key, default) do
    case params[key] do
      value when is_binary(value) ->
        case Integer.parse(value) do
          {int, ""} -> int
          _ -> default
        end

      _ ->
        default
    end
  end
end
