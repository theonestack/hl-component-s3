CloudFormation do

  buckets = external_parameters.fetch(:buckets, {})
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

      Condition("#{safe_bucket_name}SetLogFilePrefix", FnNot(FnEquals(Ref("#{safe_bucket_name}LogFilePrefix"), ''))) if config.has_key? 'enable_logging' and config['enable_logging']

      S3_Bucket("#{safe_bucket_name}") do
        AccessControl config['access_control'] if config.has_key?('access_control')
        DeletionPolicy 'Retain' if (config.has_key?('deletion_policy') && config['deletion_policy'] == 'Retain' )
        BucketName FnSub(bucket_name)
        Tags([
          { Key: 'Name', Value: FnSub("${EnvironmentName}-#{bucket}") },
          { Key: 'Environment', Value: Ref("EnvironmentName") },
          { Key: 'EnvironmentType', Value: Ref("EnvironmentType") }
        ])
        NotificationConfiguration notification_configurations unless notification_configurations.empty?
        LifecycleConfiguration({ Rules: config['lifecycle_rules'] }) if config.has_key?('lifecycle_rules')
        AccelerateConfiguration({ AccelerationStatus: config['acceleration_status'] }) if config.has_key?('acceleration_status')
        PublicAccessBlockConfiguration config['public_access_block_configuration'] if config.has_key?('public_access_block_configuration')
        VersioningConfiguration({ Status: config['versioning_configuration'] }) if config.has_key?('versioning_configuration')
        BucketEncryption config['bucket_encryption'] if config.has_key?('bucket_encryption')
        LoggingConfiguration ({
          DestinationBucketName: Ref("#{safe_bucket_name}AccessLogsBucket"),
          LogFilePrefix: FnIf("#{safe_bucket_name}SetLogFilePrefix", Ref("#{safe_bucket_name}LogFilePrefix"), Ref('AWS::NoValue'))
        }) if config.has_key?('enable_logging') && config['enable_logging']
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
    Output(safe_bucket_name + 'DomainName') { Value(FnGetAtt(safe_bucket_name, 'DomainName')) }


    if config.has_key?('bucket-policy')
        policy_document = {}
        policy_document["Statement"] = []

        config['bucket-policy'].each do |sid, statement_config|
            statement = {}
            statement["Sid"] = sid
            statement['Effect'] = statement_config.has_key?('effect') ? statement_config['effect'] : "Allow"
            statement['Principal'] = statement_config.has_key?('principal') ? statement_config['principal'] : {AWS: FnSub("arn:aws:iam::${AWS::AccountId}:root")}
            statement['Resource'] = statement_config.has_key?('resource') ? statement_config['resource'] : [FnJoin("",["arn:aws:s3:::", Ref(safe_bucket_name)]), FnJoin("",["arn:aws:s3:::", Ref(safe_bucket_name), "/*"])]
            statement['Action'] = statement_config.has_key?('actions') ? statement_config['actions'] : ["s3:*"]
            statement['Condition'] = statement_config['conditions'] if statement_config.has_key?('conditions')
            policy_document["Statement"] << statement
        end

        S3_BucketPolicy("#{safe_bucket_name}Policy") do
            Bucket Ref(safe_bucket_name)
            PolicyDocument policy_document
        end
    end


  end

end