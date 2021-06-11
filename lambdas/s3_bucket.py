import sys
import os
import boto3

sys.path.append(f"{os.environ['LAMBDA_TASK_ROOT']}/lib")
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

import json
import cr_response


def handler(event, context):
    print(f"Received event:{json.dumps(event)}")

    lambda_response = cr_response.CustomResourceResponse(event)
    params = event['ResourceProperties']
    print(f"Resource Properties {params}")

    bucket = params['BucketName']
    region = params['Region']
    notifications = []
    if "Notifications" in params:
        notifications = params['Notifications']
    
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

  bucket_name = params['BucketName']
  try:
    s3 = boto3.client('s3')
    if params['Region'] == 'us-east-1':
      bucket = s3.create_bucket(Bucket=bucket_name)
      if notifications:
              add_notification(notifications, bucket_name)
    else:
      bucket = s3.create_bucket(
                  Bucket=bucket_name,
                  CreateBucketConfiguration={
                    'LocationConstraint': params['Region']
                  }
                  )
      if notifications :
          add_notification(notifications, bucket_name)
    print(f"created bucket {bucket_name} in {bucket['Location']}")
  except Exception as e:
    print(f"bucket {bucket_name} already exists - {e}")

def update_bucket(params, event, context):
  if 'BucketName' not in params:
    raise Exception('BucketName parameter is required')
  notifications = params['Notifications']
  bucket_name = params['BucketName']
  if notifications:
      add_notification(notifications, bucket_name)
  else:
      delete_notification(bucket_name)
  print(f"TODO implement more update functions")

def add_notification(Notifications, Bucket):
  try:
      bucket_notification = s3.BucketNotification(Bucket)
        
      if "LambdaConfigurations" in Notifications:
        sw=Notifications['LambdaConfigurations'][0]
        sw['Events'] = sw.pop('Event')
        sw['LambdaFunctionArn'] = sw.pop('Function')  
        Notifications['lambda_function_configurations'] = Notifications.pop('LambdaConfigurations')
      if "QueueConfigurations" in Notifications:
        sw=Notifications['QueueConfigurations'][0]
        sw['Events'] = sw.pop('Event')
        sw['QueueArn'] = sw.pop('Queue')  
        Notifications['queue_configurations'] = Notifications.pop('QueueConfigurations')
      if "TopicConfigurations" in Notifications:
        sw=Notifications['TopicConfigurations'][0]
        sw['Events'] = sw.pop('Event')
        sw['QueueArn'] = sw.pop('Queue')
        notifications['topic_configurations'] = notifications.pop('TopicConfigurations')


      response = bucket_notification.put(
          NotificationConfiguration = Notifications
          )
      print(f"Put notification request completed... for {Bucket} :)")  
  except Exception as e:
      print(f"bucket notification for {Bucket} failed :( - {e}")
def delete_notification(Bucket):
    try:
        bucket_notification = s3.BucketNotification(Bucket)
        response = bucket_notification.put(
            NotificationConfiguration={}
            )
        
        print(f"Put notification deletion request completed... for {Bucket} :)")  

    except Exception as e:
        print(f"bucket notification deletion for {Bucket} failed :( - {e}")
