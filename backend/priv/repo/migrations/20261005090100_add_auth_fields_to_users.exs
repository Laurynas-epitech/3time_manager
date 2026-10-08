defmodule TimeManager.Repo.Migrations.AddAuthFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :password_hash, :string
      add :role_id, references(:roles, on_delete: :restrict)
    end

    create index(:users, [:role_id])
    create unique_index(:users, [:email])

    # Preserve existing users as employees; an admin must set their first password.
    execute(
      "UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'employee') WHERE role_id IS NULL",
      "SELECT 1"
    )
  end
end
