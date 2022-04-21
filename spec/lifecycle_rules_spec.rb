require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/lifecycle_rules.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/lifecycle_rules/s3.compiled.yaml") }
  
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
      
      it "to have property LifecycleConfiguration" do
          expect(resource["Properties"]["LifecycleConfiguration"]).to eq({"Rules"=>[{"Id"=>"myCustomRule", "ExpirationInDays"=>2555, "Prefix"=>"logs/", "Status"=>"Enabled", "Transitions"=>[{"StorageClass"=>"STANDARD_IA", "TransitionInDays"=>7}, {"StorageClass"=>"GLACIER", "TransitionInDays"=>30}]}, {"Id"=>"myOtherRule", "ExpirationInDays"=>2555, "Prefix"=>"documents/", "Status"=>"Enabled", "Transitions"=>[{"StorageClass"=>"STANDARD_IA", "TransitionInDays"=>7}]}]})
      end
      
    end
    
  end

end