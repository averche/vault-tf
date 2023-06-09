terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    vault = {
      source = "hashicorp/vault"
    }
  }
}

provider "docker" {}

resource "docker_container" "vault" {
  name  = "vault"
  image = "vault:1.13.0"
  ports {
    internal = 8200
    external = 8200
  }
  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=my-root-token",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
    "VAULT_ADDR=http://127.0.0.1:8200",
  ]
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = "my-root-token"
}

resource "vault_mount" "kv-v1" {
  path = "kv-v1"
  type = "kv"
  options = {
    version = "1"
  }
}

resource "vault_mount" "kv-v2" {
  path = "kv-v2"
  type = "kv"
  options = {
    version = "2"
  }
}

resource "vault_generic_secret" "my_secret_v1" {
  path = "${vault_mount.kv-v1.path}/secret"
  data_json = jsonencode({
    password = "my-password-v1"
  })
}

resource "vault_generic_secret" "my_secret_v2" {
  path = "${vault_mount.kv-v2.path}/secret"
  data_json = jsonencode({
    password = "my-password-v2"
  })
}

output "secret_password_v1" {
  value     = "${vault_generic_secret.my_secret_v1.data["password"]}"
  sensitive = true
}

output "secret_password_v2" {
  value     = "${vault_generic_secret.my_secret_v2.data["password"]}"
  sensitive = true
}
