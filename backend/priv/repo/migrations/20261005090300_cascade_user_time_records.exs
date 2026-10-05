defmodule TimeManager.Repo.Migrations.CascadeUserTimeRecords do
  use Ecto.Migration

  # Deleting a user used to fail because of their clocks / working times.
  def change do
    alter table(:workingtime) do
      modify :user_id, references(:users, on_delete: :delete_all),
        from: references(:users, on_delete: :nothing)
    end

    alter table(:clocks) do
      modify :user_id, references(:users, on_delete: :delete_all),
        from: references(:users, on_delete: :nothing)
    end
  end
end
