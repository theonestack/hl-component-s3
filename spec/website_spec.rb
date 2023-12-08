require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/website.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/website/s3.compiled.yaml") }
  
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
      
      it "to have property WebsiteConfiguration" do
          expect(resource["Properties"]["WebsiteConfiguration"]).to eq({"ErrorDocument"=>"error.html", "IndexDocument"=>"index.html", "RoutingRules"=>[{"RedirectRule"=>{"HostName"=>"test1", "HttpRedirectCode"=>"301", "Protocol"=>"http", "ReplaceKeyWith"=>"test1"}, "RoutingRuleCondition"=>{"HttpErrorCodeReturnedEquals"=>"400", "KeyPrefixEquals"=>"test1"}}, {"RedirectRule"=>{"ReplaceKeyPrefixWith"=>"documents/"}, "RoutingRuleCondition"=>{"KeyPrefixEquals"=>"docs/"}}]})
      end
      
    end
    
  end

end