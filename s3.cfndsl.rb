CloudFormation do

  buckets.each do |bucket, config|

    safe_bucket_name = bucket.capitalize.gsub('_','').gsub('-','')
    bucket_type = config.has_key?('type') ? config['type'] : 'default'
    bucket_name = config.has_key?('bucket_name') ? config['bucket_name'] : bucket

    if bucket_type == 'create_if_not_exists'
      Resource("#{safe_bucket_name}") do
        Type 'Custom::S3BucketCreateOnly'
        Property 'ServiceToken',FnGetAtt('S3BucketCreateOnlyCR','Arn')
        Property 'Region', Ref('AWS::Region')
        Property 'BucketName', bucket_name
      end
    else
      S3_Bucket("#{safe_bucket_name}") do
        BucketName FnSub(bucket_name)
        Tags([
          { Key: 'Name', Value: FnSub("${EnvironmentName}-#{bucket}") },
          { Key: 'Environment', Value: Ref("EnvironmentName") },
          { Key: 'EnvironmentType', Value: Ref("EnvironmentType") }
        ])
      end
    end

    if config.has_key?('ssm_parameter')
      SSM_Parameter("#{safe_bucket_name}Parameter") do
        Name FnSub(config['ssm_parameter'])
        Type 'String'
        Value Ref(safe_bucket_name)
      end
    end

  end

end