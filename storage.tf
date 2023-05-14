# this is the bucket that the images will be uploaded here
resource "aws_s3_bucket" "mybucket" {
  bucket = "employee-photo-bucket-al-900"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# enabling versioning to avoid overwriting data
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.mybucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


# add policy on s3 pucket ==> to allow 
resource "aws_s3_bucket_policy" "allow-iam-role-bucket" {
  bucket = aws_s3_bucket.mybucket.id
  policy = data.aws_iam_policy_document.allow-iam-role.json
}


# policy document of S3
data "aws_iam_policy_document" "allow-iam-role" {
  statement {
    principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::815730723158:role/S3DynamoDBFullAccessRole"]
            }
           actions = ["s3:*"]
            resources = [
                "arn:aws:s3:::employee-photo-bucket-al-900",
                "arn:aws:s3:::employee-photo-bucket-al-900/*"
            ]
  }
  }


resource "aws_dynamodb_table" "Employees-dynamodb-table" {
  name           = "Employees"
  hash_key       = "id"
   billing_mode     = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "emp-dynamodb-table"
    Environment = "production"
  }
}

