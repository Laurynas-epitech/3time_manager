defmodule TimeManager.AccountsTest do
  use TimeManager.DataCase

  alias TimeManager.Accounts
  alias TimeManager.Accounts.User

  import TimeManager.AccountsFixtures

  test "roles are predefined" do
    assert Enum.map(Accounts.list_roles(), & &1.name) == ["employee", "manager", "admin"]
  end

  test "create_user/1 hashes the password and defaults to employee" do
    assert {:ok, %User{} = user} =
             Accounts.create_user(%{"username" => "joao", "email" => unique_email(), "password" => "secret123"})

    assert user.password_hash
    refute user.password_hash == "secret123"
    assert user.password == nil
    assert Accounts.role_name(user) == "employee"
  end

  test "create_user/1 rejects short passwords and duplicated emails" do
    assert {:error, changeset} =
             Accounts.create_user(%{"username" => "a", "email" => unique_email(), "password" => "123"})

    assert %{password: [_]} = errors_on(changeset)

    user = user_fixture()

    assert {:error, changeset} =
             Accounts.create_user(%{"username" => "b", "email" => user.email, "password" => "secret123"})

    assert %{email: ["has already been taken"]} = errors_on(changeset)
  end

  test "authenticate/2" do
    user = user_fixture()
    assert {:ok, %User{id: id}} = Accounts.authenticate(user.email, valid_password())
    assert id == user.id
    assert {:error, :invalid_credentials} = Accounts.authenticate(user.email, "wrong-pass")
    assert {:error, :invalid_credentials} = Accounts.authenticate("nobody@x.com", "secret123")
  end

  test "update_user_role/2 promotes and demotes" do
    user = user_fixture()
    assert {:ok, user} = Accounts.update_user_role(user, "manager")
    assert Accounts.role_name(user) == "manager"
    assert {:error, :invalid_role} = Accounts.update_user_role(user, "god")
  end
end
