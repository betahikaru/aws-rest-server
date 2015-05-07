# encoding: utf-8
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/contrib'
require 'sinatra/partial'

require 'json'

require 'aws-sdk'
require 'dotenv'

module AwsRestServer
  class Application < Sinatra::Base
    # for Reload
    configure :development do
        register Sinatra::Reloader
    end

    # for "sinatra/content-for"
    register Sinatra::Contrib

    # for "partial 'some_partial', template_engine: :erb"
    register Sinatra::Partial
    set :partial_template_engine, :erb

    # setting for directory path
    set :root, File.join(File.dirname(__FILE__), "..", "..")
    set :views, Proc.new { File.join(root, "views") }

    # setting for session
    enable :sessions

    # dotenv
    Dotenv.load

    # Basic Auth
    use Rack::Auth::Basic do |username, password|
      username == ENV['BASIC_AUTH_USERNAME'] && password == ENV['BASIC_AUTH_PASSWORD']
    end

    helpers do
      def aws_iam_client()
        credentials = Aws::Credentials.new(
          session['AWS_ACCESS_KEY_ID'],
          session['AWS_SECRET_ACCESS_KEY']
        )
        client = Aws::IAM::Client.new(
          region: ENV['AWS_REGION'],
          credentials: credentials
        )
      end

      def get_user_policies(user_obj)
        user_policies = []
        user_name = user_obj.name

        # Format
        user_obj.policies.each do |policy|
          user_policies.push({
            UserName: policy.user_name,
            Name: policy.name,
            PolicyName: policy.policy_name,
            PolicyDocument: policy.policy_document,
          })
        end
        user_obj.attached_policies.each do |policy|
          user_policies.push({
            UserName: user_name,
            PolicyName: policy.policy_name,
            PolicyArn: policy.arn,
          })
        end

        # Result
        user_policies
      end

      def get_group_policies(group_obj)
        group_policies = []
        group_name = group_obj.name

        # Format
        group_obj.policies.each do |policy|
          group_policies.push({
            GroupName: policy.group_name,
            PolicyName: policy.policy_name,
            PolicyDocument: policy.policy_document,
          })
        end
        group_obj.attached_policies.each do |policy|
          group_policies.push({
            GroupName: group_name,
            PolicyName: policy.policy_name,
            PolicyArn: policy.arn,
          })
        end

        # Result
        group_policies
      end

    end

    post '/aws/setting' do
      key = URI.unescape(params[:AWS_ACCESS_KEY_ID])
      secret = URI.unescape(params[:AWS_SECRET_ACCESS_KEY])
      session['AWS_ACCESS_KEY_ID'] = key
      session['AWS_SECRET_ACCESS_KEY'] = secret
      {
        Result: "Updated"
      }.to_json
    end

    get '/' do
      content_type :json
      {
        services: [
          "aws"
        ]
      }.to_json
    end

    get '/aws' do
      content_type :json
      {
        services: [
          "iam"
        ]
      }.to_json
    end

    get '/aws/iam' do
      content_type :json
      {
        services: [
          "users",
          "groups",
        ]
      }.to_json
    end

    get '/aws/iam/users' do
      content_type :json

      # '/aws/iam/users?test=1'
      if params['test'] == "1" then
        return erb :'aws/iam/users/users_dummy'
      end

      begin
        client = aws_iam_client()
        resource = Aws::IAM::Resource.new(client: client)
        users_obj = resource.users
        users = []
        users_obj.each do |user_obj|
          users.push({
            UserName: user_obj.name,
            Path: user_obj.path,
            CreateDate: user_obj.create_date,
            UserId: user_obj.user_id,
            Arn: user_obj.arn
          })
        end
        {
          Users: users
        }.to_json
      rescue Aws::IAM::Errors::SignatureDoesNotMatch => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nInvalid API Key or Secret Access Key.\n(" + error.code + ")"
        }.to_json
      rescue Aws::Errors::MissingCredentialsError => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nNot set or set empty API Key or Secret Access Key."
        }.to_json
      rescue => error
        p error
        status 500
        return {
          Error: "Internal error"
        }.to_json
      end
    end

    get '/aws/iam/users/:user_name/groups' do
      content_type :json

      if params['test'] == "1" then
        return {
          UserName: params[:user_name],
          Groups: [],
        }.to_json # TODO: erb :'aws/iam/users/test_user/groups'
      end

      begin
        # Request
        client = aws_iam_client()
        resource = Aws::IAM::Resource.new(client: client)
        user_obj = resource.user(params[:user_name])
        groups_obj = user_obj.groups

        # Format
        groups = []
        groups_obj.each do |groups_obj|
          groups.push({
            GroupName: groups_obj.name,
            Path: groups_obj.path,
            CreateDate: groups_obj.create_date,
            GroupId: groups_obj.group_id,
            Arn: groups_obj.arn
          })
        end

        # Responce
        {
          UserName: user_obj.name,
          Groups: groups,
        }.to_json
      rescue Aws::IAM::Errors::SignatureDoesNotMatch => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nInvalid API Key or Secret Access Key.\n(" + error.code + ")"
        }.to_json
      rescue Aws::Errors::MissingCredentialsError => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nNot set or set empty API Key or Secret Access Key."
        }.to_json
      rescue Aws::IAM::Errors::NoSuchEntity => nosuch_error
        # Not found user specified by 'user_name'
        p nosuch_error
        status 404
        return {
          UserName: params[:user_name],
          Error: nosuch_error.to_json
        }.to_json
      rescue => error
        p error
        status 500
        return {
          UserName: params[:user_name],
          Error: "Internal error",
          ErrorDetail: error.to_json
        }.to_json
      end
    end


    get '/aws/iam/users/:user_name/policies' do
      content_type :json

      # '/aws/iam/users?test=1'
      if params['test'] == "1" then
        return {}.to_json # erb :'aws/iam/users/xxxx'
      end

      begin
        # Request
        client = aws_iam_client()
        resource = Aws::IAM::Resource.new(client: client)
        user_name = params[:user_name]
        user_obj = resource.user(user_name)

        # Format User Policies
        user_policies = get_user_policies(user_obj)

        # Format Group Policies
        groups_policies =[]
        user_obj.groups.each do |group|
          group_name = group.name
          group_obj = resource.group(group_name)
          groups_policies.concat(get_group_policies(group_obj))
        end

        # Responce
        {
          UserName: user_obj.name,
          UserPolicies: user_policies,
          GroupPolicies: groups_policies,
        }.to_json
      rescue Aws::IAM::Errors::SignatureDoesNotMatch => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nInvalid API Key or Secret Access Key.\n(" + error.code + ")"
        }.to_json
      rescue Aws::Errors::MissingCredentialsError => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nNot set or set empty API Key or Secret Access Key."
        }.to_json
      rescue Aws::IAM::Errors::NoSuchEntity => nosuch_error
        # Not found user specified by 'user_name'
        p nosuch_error
        status 404
        return {
          UserName: params[:user_name],
          Error: nosuch_error.to_json
        }.to_json
      rescue => error
        p error
        status 500
        return {
          UserName: params[:user_name],
          Error: "Internal error",
          ErrorDetail: error.to_json
        }.to_json
      end
    end

    get '/aws/iam/groups' do
      content_type :json

      # '/aws/iam/groups?test=1'
      if params['test'] == "1" then
        return erb :'aws/iam/groups/groups_dummy'
      end

      begin
        client = aws_iam_client()
        resource = Aws::IAM::Resource.new(client: client)
        groups_obj = resource.groups
        groups = []
        groups_obj.each do |groups_obj|
          groups.push({
            GroupName: groups_obj.name,
            Path: groups_obj.path,
            CreateDate: groups_obj.create_date,
            GroupId: groups_obj.group_id,
            Arn: groups_obj.arn
          })
        end
        {
          Groups: groups
        }.to_json
      rescue Aws::IAM::Errors::SignatureDoesNotMatch => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nInvalid API Key or Secret Access Key.\n(" + error.code + ")"
        }.to_json
      rescue Aws::Errors::MissingCredentialsError => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nNot set or set empty API Key or Secret Access Key."
        }.to_json
      rescue => error
        p error
        status 500
        return {
          Error: "Internal error"
        }.to_json
      end
    end

    get '/aws/iam/account_summary' do
      content_type :json

      # '/aws/iam/account_summary?test=1'
      if params['test'] == "1" then
        return erb :'aws/iam/account_summary/account_summary_dummy'
      end

      begin
        client = aws_iam_client()
        resource = Aws::IAM::Resource.new(client: client)
        summary_obj = resource.account_summary.summary_map
        summary_obj.to_json
      rescue Aws::IAM::Errors::SignatureDoesNotMatch => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nInvalid API Key or Secret Access Key.\n(" + error.code + ")"
        }.to_json
      rescue Aws::Errors::MissingCredentialsError => error
        p error
        status 500
        return {
          Error: "Failed to authentication.\nNot set or set empty API Key or Secret Access Key."
        }.to_json
      rescue => error
        p error
        status 500
        return {
          Error: "Internal error"
        }.to_json
      end
    end

    not_found do
      status 404
      {
        Error: "Not Found",
      }.to_json
    end
  end
end
