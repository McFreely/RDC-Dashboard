require 'sinatra'
require 'slim'

get '/' do
	redirect '/manage'
end

get '/manage' do
	slim :manage
end

post '/query/new' do
	@title= "#{params[:query][:title]}"
	@sentence = "You addded: #{@title}"
	slim :manage
end


