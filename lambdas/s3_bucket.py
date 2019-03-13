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

    try:
        if event['RequestType'] == 'Create':
            event['PhysicalResourceId'] = params['BucketName']
            create_bucket(params, event, context)
            lambda_response.respond()
        elif event['RequestType'] == 'Update':
            event['PhysicalResourceId'] = params['BucketName']
            update_bucket(params, event, context)
            lambda_response.respond()
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
    bucket = s3.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={
                  'LocationConstraint': params['Region']
                }
                )
    print(f"created bucket {bucket_name} in {bucket['Location']}")
  except Exception as e:
    print(f"bucket {bucket_name} already exists - {e}")

def update_bucket(params, event, context):
  if 'BucketName' not in params:
    raise Exception('BucketName parameter is required')

  bucket_name = params['BucketName']
  print(f"ignoring updates to bucket {bucket_name}")
  print(f"TODO implement updates")