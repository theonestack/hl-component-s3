CloudFormation do

  buckets.each do |bucket, config|

    safe_bucket_name = bucket.capitalize.gsub('_','').gsub('-','')
    bucket_type = config.has_key?('type') ? config['type'] : 'default'
    bucket_name = config.has_key?('bucket_name') ? config['bucket_name'] : bucket
    
    notification_configurations = {}
    if config.has_key?('notifications')
        if config['notifications'].has_key?('lambda')
            notification_configurations['LambdaConfigurations'] = []
            config['notifications']['lambda'].each do |values|
                lambda_config = {}
                lambda_config['Function'] = values['function']
                lambda_config['Event'] = values['event']
                notification_configurations['LambdaConfigurations'] << lambda_config
            end
        end
    end


    if bucket_type == 'create_if_not_exists'
      Resource("#{safe_bucket_name}") do
        Type 'Custom::S3BucketCreateOnly'
        Property 'ServiceToken',FnGetAtt('S3BucketCreateOnlyCR','Arn')
        Property 'Region', Ref('AWS::Region')
        Property 'BucketName', FnSub(bucket_name)
      end
    else
      S3_Bucket("#{safe_bucket_name}") do
        BucketName FnSub(bucket_name)
        Tags([
          { Key: 'Name', Value: FnSub("${EnvironmentName}-#{bucket}") },
          { Key: 'Environment', Value: Ref("EnvironmentName") },
          { Key: 'EnvironmentType', Value: Ref("EnvironmentType") }
        ])
        NotificationConfiguration notification_configurations unless notification_configurations.empty?
        LifecycleConfiguration({ Rules: config['lifecycle_rules'] }) if config.has_key?('lifecycle_rules')
      end
    end

    if config.has_key?('ssm_parameter')
      SSM_Parameter("#{safe_bucket_name}Parameter") do
        Name FnSub(config['ssm_parameter'])
        Type 'String'
        Value Ref(safe_bucket_name)
      end
    end

    Output(safe_bucket_name) { Value(Ref(safe_bucket_name)) }

  end if defined? buckets

end