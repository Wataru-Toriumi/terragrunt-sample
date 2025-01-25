include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3-lambda"
}

inputs = {
  bucket_name          = "my-prod-bucket"
  lambda_function_name = "my-prod-lambda"
  lambda_runtime       = "python3.9"
  s3_events            = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  filter_prefix        = "uploads/prod/"
}