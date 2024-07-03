## Traefik variables

# The version of Traefik to deploy.
variable "traefik_release_version" {
  type        = string
  default     = "24.0.0"
  description = "The version of Traefik to deploy."
}

# The name of the Traefik Helm release.
variable "traefik_release_name" {
  type        = string
  default     = "traefik"
  description = "The name of the Traefik Helm release."
}

# The namespace where Traefik should be deployed.
variable "traefik_release_namespace" {
  type        = string
  default     = "traefik"
  description = "The namespace where Traefik should be deployed."
}

# Whether to create the Traefik namespace if it doesn't exist.
variable "traefik_create_namespace" {
  type        = bool
  default     = true
  description = "Whether to create the Traefik namespace if it doesn't exist."
}

#TODO: add this to proper loop format instead of passing as string
# Configuration for Traefik entrypoints.
variable "traefik_enabled_entrypoints" {
  type        = string
  default     = <<EOF
ports:
  web:
    port: 8000
    expose: true
    exposedPort: 80
    protocol: TCP
  intweb:
    port: 8001
    expose: true
    exposedPort: 81
    protocol: TCP
  traefik:
    port: 9000
    expose: false
    exposedPort: 9000
    protocol: TCP
  metrics:
    port: 9100
    expose: false
    exposedPort: 9100
    protocol: TCP
EOF
  description = "Configuration for Traefik entrypoints."
}

# Whether Traefik should be the default ingress class.
variable "traefik_ingress_is_default_class" {
  type        = bool
  default     = true
  description = "Whether Traefik should be the default ingress class."
}
