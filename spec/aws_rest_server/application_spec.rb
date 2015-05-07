# encoding: utf-8
require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

require 'aws_rest_server/application'

describe AwsRestServer::Application do
  include Rack::Test::Methods

  def app
    @app ||= AwsRestServer::Application
  end

  describe "/aws/setting page" do
    it "return 200 OK" do
      key = URI.escape(ENV['AWS_ACCESS_KEY_ID'])
      secret = URI.escape(ENV['AWS_SECRET_ACCESS_KEY'])
      basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
      post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
      expect(last_response).to be_ok
    end
  end

  %w{
    /aws/iam/users
    /aws/iam/users/api_aws_iam/groups
    /aws/iam/users/api_aws_iam/policies
    /aws/iam/groups
    /aws/iam/groups/aws_sdk_iam_full/policies
    /aws/iam/account_summary
    }.each do |uri|
    describe "Exists '#{uri}' page" do
      describe "when Valid IAM User set" do
        before do
          key = URI.escape(ENV['AWS_ACCESS_KEY_ID'])
          secret = URI.escape(ENV['AWS_SECRET_ACCESS_KEY'])
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
        end

        it "return 200 OK" do
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          get uri
          expect(last_response).to be_ok
        end
      end

      describe "when Invalid IAM User set" do
        before do
          key = ""
          secret = ""
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
        end

        it "return 500 Internal Error" do
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          get uri
          expect(last_response.status).to eq 500
        end
      end
    end

    describe "Without Authorization, exists '#{uri}' page" do
      describe "when Valid IAM User set" do
        before do
          key = URI.escape(ENV['AWS_ACCESS_KEY_ID'])
          secret = URI.escape(ENV['AWS_SECRET_ACCESS_KEY'])
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
        end
        it "return 401 Unauthorized (without Authorization: in header)" do
          basic_authorize(nil, nil)
          get uri
          expect(last_response).to be_unauthorized
        end
      end
    end
  end

  %w{
    /aws/iam/users/user_name_not_exists/groups
    /aws/iam/users/user_name_not_exists/policies
    /aws/iam/groups/group_name_not_exists/policies
    }.each do |uri|
    describe "Not Exists '#{uri}' page" do
      describe "when Valid IAM User set" do
        before do
          key = URI.escape(ENV['AWS_ACCESS_KEY_ID'])
          secret = URI.escape(ENV['AWS_SECRET_ACCESS_KEY'])
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
        end

        it "return 404 Not Found" do
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          get uri
          expect(last_response).to be_not_found
        end
      end

      describe "when Invalid IAM User set" do
        before do
          key = ""
          secret = ""
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
        end

        it "return 500 Internal Error" do
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          get uri
          expect(last_response.status).to eq 500
        end
      end
    end

    describe "Without Authorization, not exists '#{uri}' page" do
      describe "when Valid IAM User set" do
        before do
          key = URI.escape(ENV['AWS_ACCESS_KEY_ID'])
          secret = URI.escape(ENV['AWS_SECRET_ACCESS_KEY'])
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
        end

        it "return 401 Unauthorized (without Authorization: in header)" do
          basic_authorize(nil, nil)
          get uri
          expect(last_response).to be_unauthorized
        end
      end
    end
  end

  %w{
    /
    /aws
    /aws/iam
    /aws/iam/users?test=1
    /aws/iam/users/user_name/groups?test=1
    /aws/iam/users/user_name/policies?test=1
    /aws/iam/groups?test=1
    /aws/iam/groups/group_name/policies?test=1
    /aws/iam/account_summary?test=1
    }.each do |uri|
    describe "Exists '#{uri}' page" do
      describe "when Valid IAM User set" do
        before do
          key = URI.escape(ENV['AWS_ACCESS_KEY_ID'])
          secret = URI.escape(ENV['AWS_SECRET_ACCESS_KEY'])
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          post '/aws/setting', AWS_ACCESS_KEY_ID: key, AWS_SECRET_ACCESS_KEY: secret
        end

        it "return 200 OK" do
          basic_authorize(ENV['BASIC_AUTH_USERNAME'], ENV['BASIC_AUTH_PASSWORD'])
          get uri
          expect(last_response).to be_ok
        end
      end
    end
  end

end
