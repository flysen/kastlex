defmodule Kastlex.Router do
  require Logger

  use Kastlex.Web, :router
  use Plug.ErrorHandler

  import Kastlex.Helper

  pipeline :api do
    plug :accepts, ~w(json)
  end

  pipeline :auth do
    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource
    plug Kastlex.Plug.EnsureAuthenticated
  end

  scope "/", Kastlex do
    pipe_through :api
    post "/rest/kafka/v0/:topic", KastleController, :create
    post "/rest/kafka/v0/:topic/:partition", KastleController, :create
    post "/login", LoginController, :login
    get "/favicon.ico", CatchAllController, :favicon
  end

  scope "/admin", as: :admin, alias: Kastlex.Admin do
    pipe_through [:api, :auth]
    get "/reload", AdminController, :reload
  end

  scope "/api/v1", as: :api_v1, alias: Kastlex.API.V1 do
    pipe_through [:api, :auth]
    get  "/topics", TopicController, :list_topics
    get  "/topics/:topic", TopicController, :show_topic
    get  "/brokers", BrokerController, :list_brokers
    get  "/brokers/:broker", BrokerController, :show_broker
    get  "/offsets/:topic/:partition", OffsetController, :show_offsets
    post "/messages/:topic/:partition", MessageController, :produce
    get  "/messages/:topic/:partition/:offset", MessageController, :fetch
    get  "/urp", UrpController, :list_urps
    get  "/urp/:topic", UrpController, :show_urps
    get  "/consumers", ConsumerController, :list_groups
    get  "/consumers/:group_id", ConsumerController, :show_group
  end

  def handle_errors(conn, data) do
    Logger.error "#{inspect data}"
    send_json(conn, conn.status, %{error: "Something went wrong"})
  end

end
