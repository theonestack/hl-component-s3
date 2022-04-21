require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/public_access_block_configuration.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/public_access_block_configuration/s3.compiled.yaml") }
  
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
      
      it "to have property PublicAccessBlockConfiguration" do
          expect(resource["Properties"]["PublicAccessBlockConfiguration"]).to eq({"BlockPublicAcls"=>true, "BlockPublicPolicy"=>true, "IgnorePublicAcls"=>false, "RestrictPublicBuckets"=>false})
      end
      
      it "to have property VersioningConfiguration" do
          expect(resource["Properties"]["VersioningConfiguration"]).to eq({"Status"=>"Enabled"})
      end
      
    end
    
  end

end