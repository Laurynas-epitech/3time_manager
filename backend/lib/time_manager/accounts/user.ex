defmodule TimeManager.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    belongs_to :role, TimeManager.Accounts.Role
    many_to_many :teams, TimeManager.Teams.Team, join_through: "team_users"

    timestamps(type: :utc_datetime)
  end

  @doc "Profile changes (username / email). Never touches the role."
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email])
    |> validate_required([:username, :email])
    |> validate_email()
  end

  @doc "Used when creating an account: needs a password."
  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> hash_password()
  end

  @doc "Password change, optional on profile update."
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> hash_password()
  end

  @doc "Promotion / demotion. Only called by admin-only code paths."
  def role_changeset(user, role_id) do
    user
    |> change(role_id: role_id)
    |> validate_required([:role_id])
    |> foreign_key_constraint(:role_id)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
  end

  defp hash_password(changeset) do
    changeset = validate_length(changeset, :password, min: 6, max: 72)

    password = get_change(changeset, :password)

    if changeset.valid? and is_binary(password) do
      changeset
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
