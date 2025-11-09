Testcontainers.start_link()
config = %Testcontainers.Container{image: "elasticsearch:8.18.8"}
{:ok, container} = Testcontainers.start_container(config)
System.put_env("ELASTICSEARCH_HOST", container.ip_address)

ExUnit.start()
