# Time Manager API

Phoenix JSON API backed by PostgreSQL. Authentication uses a Joken JWT in an
HttpOnly cookie and a matching CSRF header. Each protected request reloads the
current database role.

See the [project README](../README.md) for Docker setup, migrations and explicit
administrator bootstrap. `mix setup` invokes seeds, so it requires `ADMIN_EMAIL`
and `ADMIN_PASSWORD` (or `ADMIN_PASSWORD_FILE`).

With Elixir 1.17, Erlang/OTP 27 and disposable PostgreSQL on localhost:

```sh
mix deps.get
MIX_ENV=test mix precommit
```

The test database settings are in `config/test.exs`. The alias compiles with
warnings-as-errors, checks unused dependencies, formats code and runs tests.
See [testing](../docs/testing.md) for isolation/browser checks and
[security](../docs/security.md) for permission boundaries.
