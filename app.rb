# coding: utf-8
require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/base'
require 'json'
require 'net/http'
require 'uri'

set :bind, '0.0.0.0'

class MainApp < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'config.yml'

  get '/json' do
    json_data = open('./notifier.json') do |io|
      JSON.load(io)
    end
    res = post_to_letschat(json_data)

    p "code -> #{res.code}"
    p "message -> #{res.message}"
    p "body -> #{res.body}"
  end

  post '/notification' do
    json = JSON.parse request.body.read
    post_to_letschat(json)
  end

  helpers do
    def post_to_letschat(json)
      build_name = json['name']
      build_status = json['build']['status']
      build_number = json['build']['number']
      build_url = json['build']['full_url']

      result = sprintf(settings.message_template, build_status, build_name, build_number, build_url)
      post({"text" => result, "room" => settings.lets_chat['room']}.to_json)
    end

    def post(json)
      post_uri = URI.parse(settings.lets_chat['url'])
      http = Net::HTTP.new(post_uri.host, post_uri.port)

      req = Net::HTTP::Post.new(post_uri.request_uri)
      req.add_field 'Accept', 'application/json'
      req.add_field 'Content-Type', 'application/json'
      req.body = json 
      req.basic_auth settings.auth['user'], settings.auth['pass']
      http.request(req)
    end
  end
end
