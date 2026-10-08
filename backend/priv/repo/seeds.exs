# Explicit admin bootstrap, run separately with administrator DB credentials.
alias TimeManager.Accounts

email = System.fetch_env!("ADMIN_EMAIL")

case Accounts.get_user_by_email(email) do
  nil ->
    password =
      case System.get_env("ADMIN_PASSWORD_FILE") do
        nil -> System.fetch_env!("ADMIN_PASSWORD")
        path -> path |> File.read!() |> String.trim()
      end

    {:ok, _} =
      Accounts.create_user(
        %{"username" => "admin", "email" => email, "password" => password},
        "admin"
      )

    IO.puts("Administrator created; credentials were not logged.")

  user ->
    if Accounts.role_name(user) != "admin" do
      raise "ADMIN_EMAIL already belongs to a non-administrator; resolve explicitly"
    end

    IO.puts("Administrator already exists.")
end
