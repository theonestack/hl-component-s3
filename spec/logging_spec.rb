require 'yaml'

describe 'compiled component s3' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/logging.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/logging/s3.compiled.yaml") }
  
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
      
      it "to have property BucketEncryption" do
          expect(resource["Properties"]["BucketEncryption"]).to eq({"ServerSideEncryptionConfiguration"=>[{"ServerSideEncryptionByDefault"=>{"SSEAlgorithm"=>"AES256"}}]})
      end
      
      it "to have property LoggingConfiguration" do
          expect(resource["Properties"]["LoggingConfiguration"]).to eq({"DestinationBucketName"=>{"Ref"=>"NormalbucketAccessLogsBucket"}, "LogFilePrefix"=>{"Fn::If"=>["NormalbucketSetLogFilePrefix", {"Ref"=>"NormalbucketLogFilePrefix"}, {"Ref"=>"AWS::NoValue"}]}})
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
          expect(resource["Properties"]["PolicyDocument"]).to eq({"Statement"=>[{"Sid"=>"loadbalancer-logs", "Effect"=>"Allow", "Principal"=>{"AWS"=>"arn:aws:iam::111111111111:root"}, "Resource"=>[{"Fn::Join"=>["", ["arn:aws:s3:::", {"Ref"=>"Normalbucket"}]]}, {"Fn::Join"=>["", ["arn:aws:s3:::", {"Ref"=>"Normalbucket"}, "/*"]]}], "Action"=>["s3:PutObject"]}]})
      end
      
    end
    
  end

end