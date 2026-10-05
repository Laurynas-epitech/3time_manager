defmodule TimeManager.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :manager_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:manager_id])

    # Join table: an employee can belong to several teams.
    create table(:team_users, primary_key: false) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create unique_index(:team_users, [:team_id, :user_id])
    create index(:team_users, [:user_id])
  end
end
