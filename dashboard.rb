require 'sinatra'
require 'slim'

get '/' do
	redirect '/manage'
end

get '/manage' do
	slim :manage
end
