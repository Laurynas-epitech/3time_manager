defmodule TimeManager.Repo.Migrations.EnforceRequiredTimeFields do
  use Ecto.Migration

  def up do
    execute """
    DO $$ BEGIN
      IF EXISTS (SELECT 1 FROM users WHERE username IS NULL OR email IS NULL)
        OR EXISTS (SELECT 1 FROM clocks WHERE time IS NULL OR user_id IS NULL)
        OR EXISTS (SELECT 1 FROM workingtime WHERE start IS NULL OR "end" IS NULL OR user_id IS NULL)
      THEN RAISE EXCEPTION 'Required-field preflight failed: repair NULL users.username/email, clocks.time/user_id or workingtime.start/end/user_id from verified source data before retrying; no rows changed';
      END IF;
    END $$;
    """
    execute "ALTER TABLE users ALTER COLUMN username SET NOT NULL, ALTER COLUMN email SET NOT NULL"
    execute "ALTER TABLE clocks ALTER COLUMN time SET NOT NULL, ALTER COLUMN user_id SET NOT NULL"
    execute "ALTER TABLE workingtime ALTER COLUMN start SET NOT NULL, ALTER COLUMN \"end\" SET NOT NULL, ALTER COLUMN user_id SET NOT NULL"
  end

  def down do
    execute "ALTER TABLE users ALTER COLUMN username DROP NOT NULL, ALTER COLUMN email DROP NOT NULL"
    execute "ALTER TABLE clocks ALTER COLUMN time DROP NOT NULL, ALTER COLUMN user_id DROP NOT NULL"
    execute "ALTER TABLE workingtime ALTER COLUMN start DROP NOT NULL, ALTER COLUMN \"end\" DROP NOT NULL, ALTER COLUMN user_id DROP NOT NULL"
  end
end
