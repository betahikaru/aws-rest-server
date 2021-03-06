# encoding: utf-8
ENV['RACK_ENV'] = 'test'
require File.join(File.dirname(__FILE__), '..', 'lib', 'aws_rest_server.rb')

require 'rubygems'
require 'sinatra'
require 'rspec'
require 'rack/test'
require 'aws-sdk-core'
require 'dotenv'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

Dotenv.load
