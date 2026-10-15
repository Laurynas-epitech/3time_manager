defmodule TimeManager.Accounts do
  @moduledoc """
  The Accounts context: users, roles and credentials.
  """

  import Ecto.Query, warn: false
  alias TimeManager.{Pagination, Repo}

  alias TimeManager.Accounts.{Role, User}

  @default_role "employee"
  @max_users 500

  ## Roles (read-only)

  def list_roles, do: Repo.all(from r in Role, order_by: r.id)

  def get_role_by_name(name), do: Repo.get_by(Role, name: name)

  ## Users

  @doc """
  Lists users (at most #{@max_users} per page). Filters, all optional:
  `"ids"` (trusted, set by the caller), exact `"email"` / `"username"`,
  and `"limit"` / `"offset"` paging.
  """
  def list_users(filters \\ %{}) do
    filters
    |> Enum.reduce(User, &filter_users/2)
    |> order_by(:id)
    |> Pagination.paginate(filters, @max_users)
    |> Repo.all()
    |> Repo.preload(:role)
  end

  defp filter_users({"ids", ids}, query) when is_list(ids), do: where(query, [u], u.id in ^ids)

  defp filter_users({"manager_id", manager_id}, query) do
    members = TimeManager.Teams.managed_user_query(manager_id)
    where(query, [u], u.id == ^manager_id or u.id in subquery(members))
  end

  defp filter_users({"email", email}, query) when is_binary(email),
    do: where(query, [u], u.email == ^email)

  defp filter_users({"username", name}, query) when is_binary(name),
    do: where(query, [u], u.username == ^name)

  defp filter_users({"member_candidates_for", manager_id}, query) do
    members = TimeManager.Teams.managed_user_query(manager_id)
    employee_role = get_role_by_name("employee")
    where(query, [u], u.role_id == ^employee_role.id or u.id in subquery(members))
  end

  defp filter_users(_, query), do: query

  def get_user!(id), do: User |> Repo.get!(id) |> Repo.preload(:role)

  def get_user(nil), do: nil

  def get_user(id) do
    case Repo.get(User, id) do
      nil -> nil
      user -> Repo.preload(user, :role)
    end
  end

  def get_user_by_email(email) when is_binary(email) do
    case Repo.get_by(User, email: email) do
      nil -> nil
      user -> Repo.preload(user, :role)
    end
  end

  @doc """
  Creates a user with a password. The role defaults to `employee`;
  pass `role_name` (admin-only code paths) to choose another one.
  """
  def create_user(attrs, role_name \\ @default_role) do
    case get_role_by_name(role_name) do
      nil ->
        {:error, :invalid_role}

      %Role{id: role_id} ->
        %User{role_id: role_id}
        |> User.registration_changeset(attrs)
        |> Repo.insert()
        |> preload_role()
    end
  end

  @doc "Updates username/email, and the password if one is given."
  def update_user(%User{} = user, attrs) do
    changeset = User.changeset(user, attrs)

    changeset =
      case attrs["password"] || attrs[:password] do
        password when is_binary(password) and password != "" ->
          User.password_changeset(changeset, %{"password" => password})

        _ ->
          changeset
      end

    changeset
    |> Repo.update()
    |> preload_role()
  end

  def update_user_role(%User{} = user, role_name) do
    case get_role_by_name(role_name) do
      nil ->
        {:error, :invalid_role}

      %Role{id: role_id} ->
        user
        |> User.role_changeset(role_id)
        |> Repo.update()
        |> case do
          {:ok, user} -> {:ok, Repo.preload(user, :role, force: true)}
          error -> error
        end
    end
  end

  def delete_user(%User{} = user), do: Repo.delete(user)

  def change_user(%User{} = user, attrs \\ %{}), do: User.changeset(user, attrs)

  @doc """
  Checks email + password. Always runs a hash to avoid timing attacks.
  """
  def authenticate(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    cond do
      user && user.password_hash && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def authenticate(_, _), do: {:error, :invalid_credentials}

  def role_name(%User{role: %Role{name: name}}), do: name
  def role_name(_), do: nil

  defp preload_role({:ok, user}), do: {:ok, Repo.preload(user, :role, force: true)}
  defp preload_role(error), do: error
end
