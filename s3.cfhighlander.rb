CfhighlanderTemplate do

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true

    buckets.each do |bucket, config|
      if config.has_key? 'enable_logging' and config['enable_logging']
        safe_bucket_name = bucket.capitalize.gsub('_','').gsub('-','')
        ComponentParam "#{safe_bucket_name}AccessLogsBucket"
        ComponentParam "#{safe_bucket_name}LogFilePrefix", ''
      end
    end

  end

  # only create lambda function if the custom resource is being used
  buckets.each do |bucket, config|
    if config.has_key? 'type' and config['type'] == 'create_if_not_exists'
      LambdaFunctions 's3_custom_resources'
      break
    end
  end

end
