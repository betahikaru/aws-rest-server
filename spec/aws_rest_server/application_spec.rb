# encoding: utf-8
require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

require 'aws_rest_server/application'

describe AwsRestServer::Application do
  include Rack::Test::Methods

  def app
    @app ||= AwsRestServer::Application
  end

  %w{
    /
    /aws
    /aws/iam
    /aws/iam/users
    /aws/iam/users?test=1
    /aws/iam/groups
    /aws/iam/groups?test=1
    }.each do |uri|
    describe "Exists '#{uri}' page" do
      it "return 200 OK" do
        get uri
        expect(last_response).to be_ok
      end
    end
  end

end
