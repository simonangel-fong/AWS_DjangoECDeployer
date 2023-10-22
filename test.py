
import boto3
session = boto3.Session(profile_name="EC-Deploy-admin")

sts = session.client("sts")
response = sts.assume_role(
    RoleArn="arn:aws:iam::099139718958:role/ec-deploy-admin-role",
    RoleSessionName="ec-deploy-admin-rolen"
)

new_session = boto3.Session(aws_access_key_id=response['Credentials']['AccessKeyId'],
                      aws_secret_access_key=response['Credentials']['SecretAccessKey'],
                      aws_session_token=response['Credentials']['SessionToken'])
ec2 = new_session.client("ec2")
print(ec2.list_instance())