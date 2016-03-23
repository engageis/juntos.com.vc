S3DirectUpload.config do |c|
  c.access_key_id = CatarseSettings.get_without_cache(:aws_access_key)
  c.secret_access_key = CatarseSettings.get_without_cache(:aws_secret_key)
  c.bucket = CatarseSettings.get_without_cache(:aws_bucket)
  c.region = 'sa-east-1'
  c.url = "https://#{CatarseSettings.get_without_cache(:aws_bucket)}.s3.amazonaws.com"
end
