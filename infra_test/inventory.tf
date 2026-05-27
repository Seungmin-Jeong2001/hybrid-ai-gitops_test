resource "local_file" "ansible_inventory" {
  content = <<-EOT
    localhost ansible_connection=local

    [all:vars]
    cluster_name=${module.eks.cluster_name}
    region=ap-northeast-2
    vpc_id=${module.vpc.vpc_id}
    cluster_endpoint=${module.eks.cluster_endpoint}
  EOT
  filename = "../ansible_test/inventory.ini"
}