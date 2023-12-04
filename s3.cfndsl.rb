CloudFormation do

  buckets = external_parameters.fetch(:buckets, {})
  buckets.each do |bucket, config|

    safe_bucket_name = bucket.capitalize.gsub('_','').gsub('-','')
    bucket_type = config.has_key?('type') ? config['type'] : 'default'
    bucket_name = config.has_key?('bucket_name') ? config['bucket_name'] : bucket
    origin_access_identity = config.has_key?('origin_access_identity') ? config['origin_access_identity'] : false

    notification_configurations = {}
    if config.has_key?('notifications')
        if config['notifications'].has_key?('lambda')
            notification_configurations['LambdaConfigurations'] = []
            config['notifications']['lambda'].each do |values|
                lambda_config = {}
                lambda_config['Function'] = values['function']
                lambda_config['Event'] = values['event']
                lambda_config['Filter'] = values['filter'] if values.has_key?('filter')
                notification_configurations['LambdaConfigurations'] << lambda_config
            end
        end
        if config['notifications'].has_key?('sqs')
            notification_configurations['QueueConfigurations'] = []
            config['notifications']['sqs'].each do |values|
                sqs_config = {}
                sqs_config['Queue'] = values['queue']
                sqs_config['Event'] = values['event']
                sqs_config['Filter'] = values['filter']
                notification_configurations['QueueConfigurations'] << sqs_config
            end
        end   
         if config['notifications'].has_key?('sns')
            notification_configurations['TopicConfigurations'] = []
            config['notifications']['sns'].each do |values|
                sns_config = {}
                sns_config['Topic'] = values['topic']
                sns_config['Event'] = values['event']
                sns_config['Filter'] = values['filter']
                notification_configurations['TopicConfigurations'] << sns_config
            end
        end

    end

    cors_configuration = {}
    if config.has_key?('cors')
      cors_rules = []
      config['cors'].each do |cors_rule|
        cors_rules.append(cors_rule)
      end
      cors_configuration['CorsRules'] = cors_rules
    end

    # ACL
    ownership_controls_rules = []
    acl_rules = config.has_key?('acl_rules') ? config['acl_rules'] : []
    acl_rules.each do |acl_rule|
      ownership_control_rule = {}
      ownership_control_rule['ObjectOwnership'] = acl_rule
      ownership_controls_rules.append(ownership_control_rule)
    end

    if bucket_type == 'create_if_not_exists'
      Resource("#{safe_bucket_name}") do
        Type 'Custom::S3BucketCreateOnly'
        Property 'ServiceToken',FnGetAtt('S3BucketCreateOnlyCR','Arn')
        Property 'Region', Ref('AWS::Region')
        Property 'BucketName', FnSub(bucket_name)
        Property 'Notifications', notification_configurations unless notification_configurations.empty?
        Property 'CorsConfiguration', cors_configuration unless cors_configuration.empty?
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
        CorsConfiguration cors_configuration unless cors_configuration.empty?
        NotificationConfiguration notification_configurations unless notification_configurations.empty?
        LifecycleConfiguration({ Rules: config['lifecycle_rules'] }) if config.has_key?('lifecycle_rules')
        AccelerateConfiguration({ AccelerationStatus: config['acceleration_status'] }) if config.has_key?('acceleration_status')
        PublicAccessBlockConfiguration config['public_access_block_configuration'] if config.has_key?('public_access_block_configuration')
        VersioningConfiguration({ Status: config['versioning_configuration'] }) if config.has_key?('versioning_configuration')
        IntelligentTieringConfiguration(config['intelligent_tiering_configuration']) if config.has_key?('intelligent_tiering_configuration')
        BucketEncryption config['bucket_encryption'] if config.has_key?('bucket_encryption')
        LoggingConfiguration ({
          DestinationBucketName: Ref("#{safe_bucket_name}AccessLogsBucket"),
          LogFilePrefix: FnIf("#{safe_bucket_name}SetLogFilePrefix", Ref("#{safe_bucket_name}LogFilePrefix"), Ref('AWS::NoValue'))
        }) if config.has_key?('enable_logging') && config['enable_logging']
        OwnershipControls ({
          Rules: ownership_controls_rules
        }) if !ownership_controls_rules.empty?
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
    Output(safe_bucket_name + 'DomainName') do 
      Value FnGetAtt(safe_bucket_name, 'DomainName')
      Export FnSub("${EnvironmentName}-#{safe_bucket_name}-domain-name")
    end

    if origin_access_identity
      CloudFront_CloudFrontOriginAccessIdentity("#{safe_bucket_name}OriginAccessIdentity") {
        CloudFrontOriginAccessIdentityConfig({
          Comment: FnSub(bucket_name)
        })
      }

      Output("#{safe_bucket_name}OriginAccessIdentity") do
        Value Ref("#{safe_bucket_name}OriginAccessIdentity")
        Export FnSub("${EnvironmentName}-#{safe_bucket_name}-origin-access-identity")
      end
    end

    if config.has_key?('bucket-policy') || origin_access_identity
      policy_document = {}
      policy_document["Statement"] = []

      if config.has_key?('bucket-policy')
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
      end

      if origin_access_identity
        statement = {}
        statement['Effect'] = 'Allow'
        statement['Principal'] = { CanonicalUser: { "Fn::GetAtt" => ["#{safe_bucket_name}OriginAccessIdentity", 'S3CanonicalUserId'] }}
        statement['Resource'] = FnJoin('', [ 'arn:aws:s3:::', Ref(safe_bucket_name), '/*'])
        statement['Action'] = 's3:GetObject'
        policy_document["Statement"] << statement
      end

      S3_BucketPolicy("#{safe_bucket_name}Policy") do
        Bucket Ref(safe_bucket_name)
        PolicyDocument policy_document
      end
    end

  end

end
