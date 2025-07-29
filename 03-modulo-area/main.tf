module "area" {
  source = "./modules/area"
  height = 5
  width  = 4
}

output "descripcion" {
  value = "El área de un 5x4 es ${module.area.area}"
}
