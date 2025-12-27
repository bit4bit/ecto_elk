import Config

config :ecto_elk, TestRepo,
  hostname: "localhost",
  username: "elastic",
  password: "elastic",
  port: 9200
