terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

##############################
# 変数定義 (module-level)
##############################
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}
variable "lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}
variable "lambda_runtime" {
  type        = string
  default     = "python3.9"
  description = "Runtime environment for the Lambda function"
}
variable "s3_events" {
  type        = list(string)
  default     = ["s3:ObjectCreated:*"]
  description = "S3 events that trigger the Lambda. E.g. s3:ObjectCreated:*, s3:ObjectRemoved:*"
}
variable "filter_prefix" {
  type        = string
  default     = ""
  description = "Filter prefix for S3 events (optional)"
}
variable "filter_suffix" {
  type        = string
  default     = ""
  description = "Filter suffix for S3 events (optional)"
}

##############################
# インラインで書く Lambda コード
##############################
# ここでは Python でシンプルにイベント内容をログ出力するだけの例
locals {
  python_inline_code = <<-EOF
    import json

    def handler(event, context):
        print("=== S3 Lambda Triggered ===")
        print("Event:", json.dumps(event))
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Hello from inline Lambda!"})
        }
  EOF
}

##############################
# インラインコードを ZIP 化する Data ソース
##############################
data "archive_file" "lambda_zip" {
  type = "zip"

  # 1つのファイルを ZIP に含める例
  source {
    content  = local.python_inline_code
    filename = "lambda_function.py"
  }

  # output_base64sha256 を使えば、source_code_hash に直接使用できる
  output_base64sha256 = true
  output_path = "${path.root}/tmp/lambda_function.zip"
}

##############################
# S3 バケット
##############################
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  # バケットポリシーやバージョニング、暗号化設定など必要に応じて追加
}

##############################
# IAM Role for Lambda
##############################
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "${var.lambda_function_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# CloudWatch Logs 出力や S3 へのアクセスなどが必要ならポリシーを追加
resource "aws_iam_role_policy_attachment" "attach_lambda_logs_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

##############################
# Lambda 関数 (inline code)
##############################
resource "aws_lambda_function" "this" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = var.lambda_runtime
  handler       = "lambda_function.handler"

  # ZIP をファイルとして渡す代わりに、base64 の ZIP データを直接指定
  # source_code_hash に archive_file のハッシュを設定し、差分検知できるようにする
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

##############################
# S3 => Lambda の通知設定
##############################
# バケットが変更を検知したら Lambda を呼び出す
resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events             = var.s3_events
    filter_prefix      = var.filter_prefix
    filter_suffix      = var.filter_suffix
  }

  # Lambda permission が先に設定されていないとエラーになる可能性があるため
  depends_on = [aws_lambda_permission.allow_s3]
}

##############################
# Lambda への呼び出し権限
##############################
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this.arn
}

##############################
# Outputs
##############################
output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "bucket_name" {
  description = "The S3 bucket name"
  value       = aws_s3_bucket.this.bucket
}