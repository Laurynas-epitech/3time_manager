defmodule TimeManager.Auth.Token do
  @moduledoc """
  JWT built with Joken (HS256, signed with the `:joken, :default_signer` secret).

  Claims: `user_id`, `role`, `csrf` + the default ones (exp, iat, nbf, iss, aud, jti).
  """
  use Joken.Config

  # 24 hours
  @ttl 24 * 60 * 60

  def ttl, do: @ttl

  @impl true
  def token_config do
    default_claims(default_exp: @ttl, iss: "time_manager", aud: "time_manager")
  end

  @doc "Creates a fresh CSRF token and a JWT that embeds it."
  def issue(user_id, role) do
    csrf = generate_csrf()

    case generate_and_sign(%{"user_id" => user_id, "role" => role, "csrf" => csrf}) do
      {:ok, jwt, _claims} -> {:ok, jwt, csrf}
      error -> error
    end
  end

  def generate_csrf do
    32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end
end
