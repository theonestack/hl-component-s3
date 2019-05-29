CfhighlanderTemplate do

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true

  end

  # only create lambda function if the custom resource is being used
  buckets.each do |bucket, config|
    if config.has_key? 'type' and config['type'] == 'create_if_not_exists'
      LambdaFunctions 's3_custom_resources'
      break
    end
  end

end
