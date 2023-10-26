require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/cors.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/cors/s3.compiled.yaml") }
  
  context "Resource" do

    
    context "Normalbucket" do
      let(:resource) { template["Resources"]["Normalbucket"] }

      it "is of type AWS::S3::Bucket" do
          expect(resource["Type"]).to eq("AWS::S3::Bucket")
      end
      
      it "to have property BucketName" do
          expect(resource["Properties"]["BucketName"]).to eq({"Fn::Sub"=>"normal-bucket"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-normal-bucket"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
      it "to have property CorsConfiguration" do
          expect(resource["Properties"]["CorsConfiguration"]).to eq({"CorsRules"=>[{"AllowedOrigins"=>["*"], "AllowedMethods"=>["GET", "PUT", "POST"], "AllowedHeaders"=>["*"]}]})
      end
      
    end
    
    context "Existsbucket" do
      let(:resource) { template["Resources"]["Existsbucket"] }

      it "is of type Custom::S3BucketCreateOnly" do
          expect(resource["Type"]).to eq("Custom::S3BucketCreateOnly")
      end
      
      it "to have property ServiceToken" do
          expect(resource["Properties"]["ServiceToken"]).to eq({"Fn::GetAtt"=>["S3BucketCreateOnlyCR", "Arn"]})
      end
      
      it "to have property Region" do
          expect(resource["Properties"]["Region"]).to eq({"Ref"=>"AWS::Region"})
      end
      
      it "to have property BucketName" do
          expect(resource["Properties"]["BucketName"]).to eq({"Fn::Sub"=>"exists-bucket"})
      end
      
      it "to have property CorsConfiguration" do
          expect(resource["Properties"]["CorsConfiguration"]).to eq({"CorsRules"=>[{"AllowedOrigins"=>["*"], "AllowedMethods"=>["GET", "PUT", "POST"], "AllowedHeaders"=>["*"]}]})
      end
      
    end
    
    context "LambdaRoleS3CustomResource" do
      let(:resource) { template["Resources"]["LambdaRoleS3CustomResource"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"lambda.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property Path" do
          expect(resource["Properties"]["Path"]).to eq("/")
      end
      
      it "to have property Policies" do
          expect(resource["Properties"]["Policies"]).to eq([{"PolicyName"=>"cloudwatch-logs", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams", "logs:DescribeLogGroups"], "Resource"=>["arn:aws:logs:*:*:*"]}]}}, {"PolicyName"=>"s3", "PolicyDocument"=>{"Statement"=>[{"Effect"=>"Allow", "Action"=>["s3:CreateBucket", "s3:DeleteBucket", "s3:PutBucketNotification", "s3:GetBucketLocation", "s3:PutBucketCors", "s3:GetBucketCors", "s3:ListBucket"], "Resource"=>"*"}]}}])
      end
      
    end
    
    context "S3BucketCreateOnlyCR" do
      let(:resource) { template["Resources"]["S3BucketCreateOnlyCR"] }

      it "is of type AWS::Lambda::Function" do
          expect(resource["Type"]).to eq("AWS::Lambda::Function")
      end
      
      it "to have property Code" do
        expect(resource["Properties"]["Code"]["S3Bucket"]).to eq("")
        expect(resource["Properties"]["Code"]["S3Key"]).to start_with("/latest/S3BucketCreateOnlyCR.s3.latest.")
      end
      
      it "to have property Environment" do
          expect(resource["Properties"]["Environment"]).to eq({"Variables"=>{"ENVIRONMENT_NAME"=>{"Ref"=>"EnvironmentName"}}})
      end
      
      it "to have property Handler" do
          expect(resource["Properties"]["Handler"]).to eq("s3_bucket.handler")
      end
      
      it "to have property MemorySize" do
          expect(resource["Properties"]["MemorySize"]).to eq(128)
      end
      
      it "to have property Role" do
          expect(resource["Properties"]["Role"]).to eq({"Fn::GetAtt"=>["LambdaRoleS3CustomResource", "Arn"]})
      end
      
      it "to have property Runtime" do
          expect(resource["Properties"]["Runtime"]).to eq("python3.8")
      end
      
      it "to have property Timeout" do
          expect(resource["Properties"]["Timeout"]).to eq(5)
      end
      
    end

    context 'Resource S3BucketCreateOnlyCRVersion' do
    
      let(:resource) { template["Resources"].select {|r| r.start_with?("S3BucketCreateOnlyCRVersion") }.keys.first }
      let(:properties) { template["Resources"][resource]["Properties"] }

      it 'has property FunctionName' do
        expect(properties["FunctionName"]).to eq({"Ref"=>"S3BucketCreateOnlyCR"})
      end

      it 'has property CodeSha256' do
        expect(properties["CodeSha256"]).to a_kind_of(String)
      end

    end
    
  end

end