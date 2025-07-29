module "area" {
  source = "./modules/area"
  height = var.height
  width  = var.width
}

output "resultado" {
  value = "El área de un ${var.height} * ${var.width} es ${module.area.area}"
}
