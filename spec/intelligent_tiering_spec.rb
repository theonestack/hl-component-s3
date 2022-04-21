require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/intelligent_tiering.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/intelligent_tiering/s3.compiled.yaml") }
  
  context "Resource" do

    
    context "Muhbucket" do
      let(:resource) { template["Resources"]["Muhbucket"] }

      it "is of type AWS::S3::Bucket" do
          expect(resource["Type"]).to eq("AWS::S3::Bucket")
      end
      
      it "to have property BucketName" do
          expect(resource["Properties"]["BucketName"]).to eq({"Fn::Sub"=>"kyle-test-intelligent-tier"})
      end
      
      it "to have property Tags" do
          expect(resource["Properties"]["Tags"]).to eq([{"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-MuhBucket"}}, {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
      end
      
      it "to have property AccelerateConfiguration" do
          expect(resource["Properties"]["AccelerateConfiguration"]).to eq({"AccelerationStatus"=>"Enabled"})
      end
      
      it "to have property VersioningConfiguration" do
          expect(resource["Properties"]["VersioningConfiguration"]).to eq({"Status"=>"Enabled"})
      end
      
      it "to have property IntelligentTieringConfigurations" do
          expect(resource["Properties"]["IntelligentTieringConfigurations"]).to eq([{"Id"=>"StingyCustomer", "Prefix"=>"2019Docs_", "Status"=>"Enabled", "TagFilters"=>[{"Key"=>"IntTier", "Value"=>"No"}], "Tierings"=>[{"AccessTier"=>"ARCHIVE_ACCESS", "Days"=>90}, {"AccessTier"=>"DEEP_ARCHIVE_ACCESS", "Days"=>365}]}])
      end
      
    end
    
  end

end