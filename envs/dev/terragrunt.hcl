include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules/s3-lambda"
}

inputs = {
  bucket_name          = "my-dev-terragrunt-sample-bucket"
  lambda_function_name = "my-dev-lambda"
  lambda_runtime       = "python3.9"
  s3_events            = ["s3:ObjectCreated:*"]  # アップロード時のみ通知
  filter_prefix        = "uploads/dev/"
  # filter_suffix       = ".csv"
}