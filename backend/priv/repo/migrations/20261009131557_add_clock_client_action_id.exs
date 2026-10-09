defmodule TimeManager.Repo.Migrations.AddClockClientActionId do
  use Ecto.Migration

  def change do
    alter table(:clocks) do
      add :client_action_id, :uuid
    end

    create unique_index(:clocks, [:user_id, :client_action_id])
  end
end
