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

    # dotenv
    Dotenv.load

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
        client = Aws::IAM::Client.new
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
      rescue => error
        p error
        return {}.to_json
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
        client = Aws::IAM::Client.new
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
      rescue Aws::IAM::Errors::NoSuchEntity => nosuch_error
        # Not found user specified by 'user_name'
        p nosuch_error
        status 404
        return {
          UserName: params[:user_name],
          Exception: nosuch_error.to_json
        }.to_json
      rescue => error
        p error
        status 500
        return {
          UserName: params[:user_name],
          Exception: error.to_json
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
        client = Aws::IAM::Client.new
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
      rescue => error
        p error
        return {}.to_json
      end
    end

    get '/aws/iam/account_summary' do
      content_type :json

      # '/aws/iam/account_summary?test=1'
      if params['test'] == "1" then
        return erb :'aws/iam/account_summary/account_summary_dummy'
      end

      begin
        client = Aws::IAM::Client.new
        resource = Aws::IAM::Resource.new(client: client)
        summary_obj = resource.account_summary.summary_map
        summary_obj.to_json
      rescue => error
        p error
        return {}.to_json
      end
    end

  end
end
