# terragrunt-sample

terragrunt を用いて、s3, lambda の構成例を作成したものです。

## 実行方法

```bash
# dev 環境の S3 + Lambda をデプロイ
cd envs/dev/s3-lambda
terragrunt plan
terragrunt apply

# 本番環境の S3 + Lambda をデプロイ
cd envs/prod/s3-lambda
terragrunt plan
terragrunt apply

# 全環境一斉に plan
cd envs
terragrunt run-all plan
```
