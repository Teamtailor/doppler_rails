# frozen_string_literal: true

RSpec.describe DopplerRails do
  describe ".load_secrets" do
    it "calls the fetch_enviroment_variables instance method" do
      expect(DopplerRails::Operations).to receive(:fetch_enviroment_variables)
      DopplerRails.load_secrets
    end
  end

  describe "#fetch_enviroment_variables" do
    let(:doppler) { DopplerRails }
    let(:fallback_file_path) { "./test-secrets" }

    before do
      File.delete(fallback_file_path) if File.exist?(fallback_file_path)
      ENV["DOPPLER_TEST_SECRET"] = nil
    end

    it "returns if ENV['DOPPLER_TOKEN'] is blank" do
      stub_const("DopplerRails::TOKEN", nil)
      expect(DopplerRails::Operations.fetch_enviroment_variables).to be_nil
    end

    context "when ENV['DOPPLER_TOKEN'] is not blank" do
      before { stub_const("DopplerRails::TOKEN", "token") }

      context "when response is successful" do
        it "updates ENV with the response body" do
          allow(DopplerRails::Operations).to receive(:connection).and_return(double(get: double(success?: true,
            body: '{"DOPPLER_TEST_SECRET": "bar"}')))
          expect {
            DopplerRails::Operations.fetch_enviroment_variables
          }.to change { ENV["DOPPLER_TEST_SECRET"] }.from(nil).to("bar")
        end

        describe "fallback file" do
          it "encrypts and stores the response" do
            stub_const("DopplerRails::FALLBACK_FILE_PATH", fallback_file_path)
            allow(DopplerRails::Operations).to receive(:connection).and_return(double(get: double(success?: true,
              body: '{"DOPPLER_TEST_SECRET": "bar"}')))
            expect_any_instance_of(ActiveSupport::MessageEncryptor).to receive(:encrypt_and_sign).with(
              '{"DOPPLER_TEST_SECRET": "bar"}'
            ) { "encrypted-string" }
            salt = SecureRandom.random_bytes(ActiveSupport::MessageEncryptor.key_len)
            expect(SecureRandom).to receive(:random_bytes).with(ActiveSupport::MessageEncryptor.key_len) { salt }

            expect {
              DopplerRails::Operations.fetch_enviroment_variables
            }.to change { File.exist?(fallback_file_path) }.to(true)
            expect(File.read(fallback_file_path,
              encoding: "ascii-8bit")).to eq("encrypted-string" + "\n" + Base64.urlsafe_encode64(salt))
          end

          it "overwrites the fallback file if already present" do
            stub_const("DopplerRails::FALLBACK_FILE_PATH", fallback_file_path)
            allow(DopplerRails::Operations).to receive(:connection).and_return(double(get: double(success?: true,
              body: '{"DOPPLER_TEST_SECRET": "bar"}')))

            new_encrypted_string = "new-encrypted-string"
            File.write(fallback_file_path, "old-encrypted-string", encoding: "ascii-8bit")
            expect(DopplerRails::Operations).to receive(:encrypt) { new_encrypted_string }

            expect {
              DopplerRails::Operations.fetch_enviroment_variables
            }.not_to change { File.exist?(fallback_file_path) }.from(true)
            expect(File.read(fallback_file_path, encoding: "ascii-8bit")).to eq(new_encrypted_string)
          end
        end
      end

      context "when response is unsuccessful" do
        context "with fallback file path" do
          before { stub_const("DopplerRails::FALLBACK_FILE_PATH", fallback_file_path) }

          context "when fallback file is present" do
            before do
              salt = SecureRandom.random_bytes(ActiveSupport::MessageEncryptor.key_len)
              key = ActiveSupport::KeyGenerator.new("token").generate_key(salt, ActiveSupport::MessageEncryptor.key_len)
              message = ActiveSupport::MessageEncryptor.new(key).encrypt_and_sign('{"DOPPLER_TEST_SECRET": "foo"}')
              File.write(fallback_file_path, message + "\n" + Base64.urlsafe_encode64(salt), encoding: "ascii-8bit")
            end

            it "updates ENV with the fallback file content" do
              allow(DopplerRails::Operations).to receive(:connection).and_return(double(get: double(success?: false)))
              expect {
                DopplerRails::Operations.fetch_enviroment_variables
              }.to change { ENV["DOPPLER_TEST_SECRET"] }.from(nil).to("foo")
            end

            it "works on errors as well" do
              stub_request(:get, "https://api.doppler.com/v3/configs/config/secrets/download?format=json")
                .to_raise(Faraday::ServerError)

              expect {
                DopplerRails::Operations.fetch_enviroment_variables
              }.to change { ENV["DOPPLER_TEST_SECRET"] }.from(nil).to("foo")
              expect(a_request(:get, "https://api.doppler.com/v3/configs/config/secrets/download?format=json"))
                .to have_been_made
            end
          end

          context "when fallback file is not present" do
            it "returns" do
              allow(DopplerRails::Operations).to receive(:connection).and_return(double(get: double(success?: false)))
              expect(DopplerRails::Operations.fetch_enviroment_variables).to be_nil
            end
          end
        end

        context "without fallback file path" do
          before { stub_const("DopplerRails::FALLBACK_FILE_PATH", nil) }

          it "returns" do
            allow(DopplerRails::Operations).to receive(:connection).and_return(double(get: double(success?: false)))
            expect(DopplerRails::Operations.fetch_enviroment_variables).to be_nil
          end
        end

        it "uses faraday retry" do
          stub_request(:get, "https://api.doppler.com/v3/configs/config/secrets/download?format=json")
            .to_timeout
            .to_timeout
            .to_return({body: '{"SECRET_TOKEN": "super-secret"}'})

          expect {
            DopplerRails::Operations.fetch_enviroment_variables
          }.to change { ENV["SECRET_TOKEN"] }.from(nil).to("super-secret")
          expect(WebMock).to have_requested(:get, "https://api.doppler.com/v3/configs/config/secrets/download?format=json").times(3)
        end
      end
    end
  end
end
