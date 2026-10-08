defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # JWT cookie + x-csrf-token header -> conn.assigns.current_user
  pipeline :auth do
    plug TimeManagerWeb.Plugs.Authenticate
  end

  pipeline :admin do
    plug TimeManagerWeb.Plugs.RequireRole, ["admin"]
  end

  # PUBLIC
  scope "/api/auth", TimeManagerWeb do
    pipe_through :api

    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  # ADMIN ONLY
  scope "/api", TimeManagerWeb do
    pipe_through [:api, :auth, :admin]

    post "/users", UserController, :create
    put "/users/:id/role", UserController, :update_role

    post "/teams", TeamController, :create
    put "/teams/:id", TeamController, :update
    delete "/teams/:id", TeamController, :delete
  end

  # ANY LOGGED-IN USER (finer checks are in the controllers, see Authorization)
  scope "/api", TimeManagerWeb do
    pipe_through [:api, :auth]

    get "/auth/me", AuthController, :me
    post "/auth/logout", AuthController, :logout

    # ROLES (read-only, predefined)
    get "/roles", RoleController, :index

    # USERS
    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    put "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete

    # TEAMS
    get "/teams", TeamController, :index
    get "/teams/:id", TeamController, :show
    post "/teams/:team_id/members/:user_id", TeamController, :add_member
    delete "/teams/:team_id/members/:user_id", TeamController, :remove_member

    # ORIGINAL WORKING TIME ROUTES
    get "/workingtime/:userID", WorkingTimeController, :index
    get "/workingtime/:userID/:id", WorkingTimeController, :show
    post "/workingtime/:userID", WorkingTimeController, :create
    put "/workingtime/:id", WorkingTimeController, :update
    delete "/workingtime/:id", WorkingTimeController, :delete

    # ASSIGNMENT-COMPATIBLE WORKING TIME ROUTES
    post "/workingTime/:userID", WorkingTimeController, :create
    put "/workingTime/:userID/:id", WorkingTimeController, :update
    delete "/workingTime/:userID/:id", WorkingTimeController, :delete

    # ORIGINAL CLOCK ROUTES
    get "/clocks/:userID", ClockController, :show
    post "/clocks/:userID", ClockController, :create

    # ASSIGNMENT-COMPATIBLE CLOCK ROUTES
    get "/clock/:userID", ClockController, :show
    post "/clock/:userID", ClockController, :create

    # CHART MANAGER
    get "/chartManager/:userID", WorkingTimeController, :index
  end

  if Application.compile_env(:time_manager, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard",
        metrics: TimeManagerWeb.Telemetry

      forward "/mailbox",
              Plug.Swoosh.MailboxPreview
    end
  end
end
