defmodule TimeManager.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def up do
    create table(:roles) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name])

    # Roles are predefined: there is no CRUD for them, only reads.
    execute """
    INSERT INTO roles (name, inserted_at, updated_at) VALUES
      ('employee', NOW(), NOW()),
      ('manager', NOW(), NOW()),
      ('admin', NOW(), NOW())
    """
  end

  def down do
    drop table(:roles)
  end
end
