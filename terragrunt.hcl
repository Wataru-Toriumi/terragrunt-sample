generate  "backend" {
  path = "backned.tf"
  if_exists = "overwrite"
  contents = <<EOF
terraform {
  backend "s3" {}
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "terragrunt-sample-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
  }
}

terraform {
  extra_arguments "common_vars" {
    commands = ["plan", "apply", "destroy"]
    optional_var_files = [
      "${get_terragrunt_dir()}/common.tfvars"
    ]
  }
}