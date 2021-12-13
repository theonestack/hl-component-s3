import sys
import os
import boto3

sys.path.append(f"{os.environ['LAMBDA_TASK_ROOT']}/lib")
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

import json
import cr_response

s3r = boto3.resource('s3')

def handler(event, context):
    print(f"Received event:{json.dumps(event)}")

    lambda_response = cr_response.CustomResourceResponse(event)
    params = event['ResourceProperties']
    print(f"Resource Properties {params}")

    bucket = params['BucketName']
    region = params['Region']
    
    arn = f'arn:aws:s3:::{bucket}'

    # Accessed using the path-style URL.
    # https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#access-bucket-intro
    if region == 'us-east-1':
        domain_name = f's3.amazonaws.com/{bucket}'
    else:
        domain_name = f's3.{region}.amazonaws.com/{bucket}'

    data = {
        'DomainName' : domain_name,
        'Arn': arn
    }

    try:
        if event['RequestType'] == 'Create':
            event['PhysicalResourceId'] = bucket
            create_bucket(params, event, context)
            lambda_response.respond(data)

        elif event['RequestType'] == 'Update':
            event['PhysicalResourceId'] = params['BucketName']
            update_bucket(params, event, context)
            lambda_response.respond(data)

        elif event['RequestType'] == 'Delete':
            print(f"ignoring deletion of bucket {params['BucketName']}")
            lambda_response.respond()

    except Exception as e:
        message = str(e)
        lambda_response.respond_error(message)
    return 'OK'

def create_bucket(params, event, context):
  if 'BucketName' not in params:
    raise Exception('BucketName parameter is required')

  notifications = params['Notifications'] if 'Notifications' in params else None
  bucket_name = params['BucketName']
  cors_configuration = params['CorsConfiguration'] if 'CorsConfiguration' in params else None
  bucket_already_exists = True

  try:
    s3 = boto3.client('s3')
    response = s3.head_bucket(Bucket=bucket_name)
    print(f"bucket {bucket_name} does already existing so we need don't need to create it")
  except Exception as e:
    if "404" in str(e):
      bucket_already_exists = False
      print(f"bucket {bucket_name} does not already existing so we need to create it")
    else:
      print(f"error:{e}\n")
      raise e


  options = {'Bucket' : bucket_name}
  if params['Region'] != 'us-east-1':
    options = dict({'CreateBucketConfiguration' : {'LocationConstraint':  params['Region']}}, **options)

  if bucket_already_exists:
    print(f"bucket {bucket_name} exists")
  else:
    bucket = s3.create_bucket(**options)
    print(f"created bucket {bucket_name} in {bucket['Location']}")

  if notifications:
    add_notification(notifications, bucket_name)

  if cors_configuration:
    add_cors(cors_configuration, bucket_name)
    
  


def update_bucket(params, event, context):
  if 'BucketName' not in params:
    raise Exception('BucketName parameter is required')

  notifications = params['Notifications'] if 'Notifications' in params else None
  bucket_name = params['BucketName']
  cors_configuration = params['CorsConfiguration'] if 'CorsConfiguration' in params else None

  if notifications:
      add_notification(notifications, bucket_name)
  else:
      delete_notification(bucket_name)
      print(f"Put notification deletion request completed... :)") 

  if cors_configuration:
    print(f"cors: {cors_configuration}\n")
    add_cors(cors_configuration, bucket_name)
  else:
      delete_cors(bucket_name)
      print(f"Cors configuration deletion request completed... :)") 

def add_notification(Notifications, Bucket):
  bucket_notification = s3r.BucketNotification(Bucket)
    
  if "LambdaConfigurations" in Notifications:
    sw=Notifications['LambdaConfigurations'][0]
    sw['Events'] = sw.pop('Event')
    sw['LambdaFunctionArn'] = sw.pop('Function')  
    if "Filter" in Notifications['QueueConfigurations'][0]:
        sw['Filter']['Key'] = sw['Filter'].pop('S3Key')
        sw['Filter']['Key']['FilterRules'] = sw['Filter']['Key'].pop('Rules')
        for i in range((len(sw['Filter']['Key']['FilterRules']))):
            sw['Filter']['Key']['FilterRules'][i]['Name'] = sw['Filter']['Key']['FilterRules'][i].pop('name')
            sw['Filter']['Key']['FilterRules'][i]['Value'] = sw['Filter']['Key']['FilterRules'][i].pop('value') 
  if "QueueConfigurations" in Notifications:
    sw=Notifications['QueueConfigurations'][0]
    sw['Events'] = sw.pop('Event')
    sw['QueueArn'] = sw.pop('Queue')  
    if "Filter" in sw:
        sw['Filter']['Key'] = sw['Filter'].pop('S3Key')
        sw['Filter']['Key']['FilterRules'] = sw['Filter']['Key'].pop('Rules')
        for i in range((len(sw['Filter']['Key']['FilterRules']))):
            sw['Filter']['Key']['FilterRules'][i]['Name'] = sw['Filter']['Key']['FilterRules'][i].pop('name')
            sw['Filter']['Key']['FilterRules'][i]['Value'] = sw['Filter']['Key']['FilterRules'][i].pop('value') 
  if "TopicConfigurations" in Notifications:
    sw=Notifications['TopicConfigurations'][0]
    sw['Events'] = sw.pop('Event')
    sw['QueueArn'] = sw.pop('Queue')
    if "Filter" in sw:
        sw['Filter']['Key'] = sw['Filter'].pop('S3Key')
        sw['Filter']['Key']['FilterRules'] = sw['Filter']['Key'].pop('Rules')
        for i in range((len(sw['Filter']['Key']['FilterRules']))):
            sw['Filter']['Key']['FilterRules'][i]['Name'] = sw['Filter']['Key']['FilterRules'][i].pop('name')
            sw['Filter']['Key']['FilterRules'][i]['Value'] = sw['Filter']['Key']['FilterRules'][i].pop('value') 
  print(f"transformed data is: {Notifications}")
  response = bucket_notification.put(
      NotificationConfiguration = Notifications
      )
  print(f"Put notification request completed... for {Bucket} :)")  

def delete_notification(Bucket):
    bucket_notification = s3r.BucketNotification(Bucket)
    response = bucket_notification.put(
        NotificationConfiguration={}
        )
    print(f"Put notification delete request completed... for {Bucket} :)")


def add_cors(cors_configuration, bucket_name):
  bucket_cors = s3r.BucketCors(bucket_name)
  cors_rules = []

  bucket_cors.put(
    CORSConfiguration={
      "CORSRules": cors_configuration['CorsRules']
    }
  )
  print(f"Put cors configuration request completed... for {bucket_name} :)")  


def delete_cors(bucket_name):
  bucket_cors = s3r.BucketCors(bucket_name)
  response = bucket_cors.delete()
  print(f"Put cors configuration delete request completed... for {bucket_name} :)")