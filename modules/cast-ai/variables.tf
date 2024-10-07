variable "enable_cast_ai_agent" {
  description = "Enable Cast AI agent"
  type        = bool
}

variable "cast_ai_agent_api_key" {
  description = "Cast AI agent API key"
  type        = string
}

variable "enable_castai_cluster_controller" {
  description = "Enable Cast AI cluster controller"
  type        = bool
}

variable "cluster_id" {
  description = "Cast AI cluster ID"
  type        = string
}

variable "enable_castai_spot_handler" {
  description = "Enable Cast AI spot handler"
  type        = bool
}
