remote_state {
  backend = "s3"
  config = {
    bucket         = "my-terragrunt-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-terragrunt-lock-table"
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