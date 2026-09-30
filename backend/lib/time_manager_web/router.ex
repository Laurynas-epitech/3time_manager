defmodule TimeManagerWeb.Router do
  use TimeManagerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TimeManagerWeb do
    pipe_through :api

    # USERS
    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    post "/users", UserController, :create
    put "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete

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