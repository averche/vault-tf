terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_container" "vault" {
  name  = "vault"
  image = "vault"

  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=root",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200"
  ]

  ports {
    internal = 8200
    external = 8200
  }
}

resource "null_resource" "wait_for_vault" {
  depends_on = [docker_container.vault]

  provisioner "local-exec" {
    command = "vault login root"
  }

  provisioner "local-exec" {
    command     = "vault secrets list"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      VAULT_ADDR = "http://${docker_container.vault.hostname}:8200"
    }
  }
}

resource "vault_generic_secret" "my_secret" {
  depends_on = [null_resource.wait_for_vault]

  path = "secret/my_secret"

  data_json = jsonencode({
    username = "hello",
    password = "pass",
  })
}

output "secret_username" {
  value     = "${vault_generic_secret.my_secret.data["username"]}"
  sensitive = true
}

output "secret_password" {
  value     = "${vault_generic_secret.my_secret.data["password"]}"
  sensitive = true
}
