# infra/plc.tf - laboratorio, NO DESPLEGAR
# Configuración simulada. Sin proveedor, sin credenciales, sin estado remoto.
variable "red_operacional_aprobada" {
  description = "CIDR ficticio aprobado para el laboratorio"
  type        = string
  default     = "192.0.2.0/24"
}
