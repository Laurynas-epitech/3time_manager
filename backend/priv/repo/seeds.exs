# Creates the default admin. Safe to run several times.
#
#     mix run priv/repo/seeds.exs
#
# Credentials can be changed with ADMIN_EMAIL / ADMIN_PASSWORD.

alias TimeManager.Accounts

email = System.get_env("ADMIN_EMAIL", "admin@timemanager.local")
password = System.get_env("ADMIN_PASSWORD", "admin1234")

case Accounts.get_user_by_email(email) do
  nil ->
    {:ok, _} =
      Accounts.create_user(%{"username" => "admin", "email" => email, "password" => password}, "admin")

    IO.puts("Admin created: #{email} / #{password}")

  _user ->
    IO.puts("Admin already exists: #{email}")
end
