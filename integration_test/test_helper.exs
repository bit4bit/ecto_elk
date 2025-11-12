Testcontainers.start_link()
config =
  Testcontainers.Container.new("docker.elastic.co/elasticsearch/elasticsearch:8.18.8")
  |> Testcontainers.Container.with_environment("ELASTIC_PASSWORD", "elastic")
  |> Testcontainers.Container.with_environment("xpack.security.enabled", "false")
  |> Testcontainers.Container.with_environment("discovery.type", "single-node")
  |> Testcontainers.Container.with_environment("cluster.name", "docker-cluster")
  |> Testcontainers.Container.with_environment("node.name", "elasticsearch")
  |> Testcontainers.Container.with_waiting_strategy(
    Testcontainers.LogWaitStrategy.new(~r/adding ingest pipeline metrics-apm/, 60_000)
  )
  |> Testcontainers.Container.with_auto_remove(false)
  |> Testcontainers.Container.with_force_reuse(true)

{:ok, container} = Testcontainers.start_container(config)
System.put_env("ELASTICSEARCH_HOST", container.ip_address)


ExUnit.start()
