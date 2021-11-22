# s3 CfHighlander component

## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | string
| EnvironmentType | Tagging | development | true | string | ['development','production']
## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |
| DnsDomainZoneId | The hosted zone ID that was created, if it was created | false

## Included Components

<none>

## Example Configuration
### Highlander
```
  Component name: 's3', template: 's3'
```

### S3 Configuration

```
buckets:
  normal-bucket:
    type: default
  create-only-bucket:
    bucket_name: ${EnvironmentName}.mybucket
    type: create_if_not_exists
    ssm_parameter: /app/my-create-only-bucket #creates a ssm parameter with bucket name
```

## Cfhighlander Setup

install cfhighlander [gem](https://github.com/theonestack/cfhighlander)

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```
## Testing Components

Running the tests

```bash
cfhighlander cftest s3
```