import Config

# Configure your database
config :time_manager, TimeManager.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "db",
  database: "time_manager_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Configure Phoenix endpoint
config :time_manager, TimeManagerWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev-only-secret-key-base-0123456789abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJ",
  watchers: []

# Enable dev routes
config :time_manager, dev_routes: true

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false
