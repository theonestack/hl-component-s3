require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/website_alias.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/website_alias/s3.compiled.yaml") }
  
  context "Resource" do

    
    context "NormalbucketS3AliasRecord" do
      let(:resource) { template["Resources"]["NormalbucketS3AliasRecord"] }

      it "is of type AWS::Route53::RecordSet" do
          expect(resource["Type"]).to eq("AWS::Route53::RecordSet")
      end
      
      it "to have property HostedZoneName" do
          expect(resource["Properties"]["HostedZoneName"]).to eq({"Fn::Sub"=>"example.com."})
      end
      
      it "to have property Name" do
          expect(resource["Properties"]["Name"]).to eq({"Fn::Sub"=>"mybucket.example.com."})
      end
      
      it "to have property Type" do
          expect(resource["Properties"]["Type"]).to eq("A")
      end
      
      it "to have property AliasTarget" do
          expect(resource["Properties"]["AliasTarget"]).to eq({"DNSName"=>"s3-website-ap-southeast-2.amazonaws.com.", "HostedZoneId"=>"Z1WCIGYICN2BYD"})
      end
      
    end
    
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
      
      it "to have property PublicAccessBlockConfiguration" do
          expect(resource["Properties"]["PublicAccessBlockConfiguration"]).to eq({"BlockPublicAcls"=>false, "BlockPublicPolicy"=>false, "IgnorePublicAcls"=>true, "RestrictPublicBuckets"=>false})
      end
      
      it "to have property WebsiteConfiguration" do
          expect(resource["Properties"]["WebsiteConfiguration"]).to eq({"ErrorDocument"=>"error.html", "IndexDocument"=>"index.html", "RoutingRules"=>[{"RedirectRule"=>{"HostName"=>"test1", "HttpRedirectCode"=>"301", "Protocol"=>"http", "ReplaceKeyWith"=>"test1"}, "RoutingRuleCondition"=>{"HttpErrorCodeReturnedEquals"=>"400", "KeyPrefixEquals"=>"test1"}}, {"RedirectRule"=>{"ReplaceKeyPrefixWith"=>"documents/"}, "RoutingRuleCondition"=>{"KeyPrefixEquals"=>"docs/"}}]})
      end
      
    end
    
    context "NormalbucketPolicy" do
      let(:resource) { template["Resources"]["NormalbucketPolicy"] }

      it "is of type AWS::S3::BucketPolicy" do
          expect(resource["Type"]).to eq("AWS::S3::BucketPolicy")
      end
      
      it "to have property Bucket" do
          expect(resource["Properties"]["Bucket"]).to eq({"Ref"=>"Normalbucket"})
      end
      
      it "to have property PolicyDocument" do
          expect(resource["Properties"]["PolicyDocument"]).to eq({"Statement"=>[{"Sid"=>"s3-website", "Effect"=>"Allow", "Principal"=>"*", "Resource"=>[{"Fn::Join"=>["", ["arn:aws:s3:::", {"Ref"=>"Normalbucket"}]]}, {"Fn::Join"=>["", ["arn:aws:s3:::", {"Ref"=>"Normalbucket"}, "/*"]]}], "Action"=>["s3:GetObject"]}]})
      end
      
    end
    
  end

end