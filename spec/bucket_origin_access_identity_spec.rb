require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/bucket_origin_access_identity.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/bucket_origin_access_identity/s3.compiled.yaml") }
  
  context "Resource" do

    
    context "Cloudfrontbucket" do
      let(:resource) { template["Resources"]["Cloudfrontbucket"] }

      it "is of type AWS::S3::Bucket" do
          expect(resource["Type"]).to eq("AWS::S3::Bucket")
      end
      
      it "to have property BucketName" do
          expect(resource["Properties"]["BucketName"]).to eq({"Fn::Sub"=>"${EnvironmentName}-cloudfront-bucket"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-cloudfront-bucket"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
    end
    
    context "CloudfrontbucketOriginAccessIdentity" do
      let(:resource) { template["Resources"]["CloudfrontbucketOriginAccessIdentity"] }

      it "is of type AWS::CloudFront::CloudFrontOriginAccessIdentity" do
          expect(resource["Type"]).to eq("AWS::CloudFront::CloudFrontOriginAccessIdentity")
      end
      
      it "to have property CloudFrontOriginAccessIdentityConfig" do
          expect(resource["Properties"]["CloudFrontOriginAccessIdentityConfig"]).to eq({"Comment"=>{"Fn::Sub"=>"${EnvironmentName}-cloudfront-bucket"}})
      end
      
    end
    
    context "CloudfrontbucketPolicy" do
      let(:resource) { template["Resources"]["CloudfrontbucketPolicy"] }

      it "is of type AWS::S3::BucketPolicy" do
          expect(resource["Type"]).to eq("AWS::S3::BucketPolicy")
      end
      
      it "to have property Bucket" do
          expect(resource["Properties"]["Bucket"]).to eq({"Ref"=>"Cloudfrontbucket"})
      end
      
      it "to have property PolicyDocument" do
          expect(resource["Properties"]["PolicyDocument"]).to eq({"Statement"=>[{"Effect"=>"Allow", "Principal"=>{"CanonicalUser"=>{"Fn::GetAtt"=>["CloudfrontbucketOriginAccessIdentity", "S3CanonicalUserId"]}}, "Resource"=>{"Fn::Join"=>["", ["arn:aws:s3:::", {"Ref"=>"Cloudfrontbucket"}, "/*"]]}, "Action"=>"s3:GetObject"}]})
      end
      
    end
    
  end

end