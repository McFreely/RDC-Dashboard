require 'rubygems'
require 'sinatra'
require 'slim'
require 'multi_json'
require 'httparty'

class Twitter
	include HTTParty
	base_uri 'search.twitter.com'

	def search(query, page)
		filters = " -filter:links
		   			-t.co
		   			-#unacteurunfilm
		   			-'go'
		   			-'vais voir'
		   			-'va voir'
		   			-'aller voir'
		   			-RT"

		@options = {:query => {:q => query + filters, :rpp => 100,
					   :page => page,
					   :lang => :fr,
					   :result_type => :recent}}

		self.class.get("/search.json", @options)['results']
	end
end

get '/' do
	redirect '/manage'
end

get '/manage' do
	slim :manage
end

post '/query/new' do
	@title = "#{params[:query][:title]}"
	@tweet_list = []
	@page = 1
	twitter = Twitter.new
	while @page  <= 15
		response = twitter.search(@title, @page)
		response.each do |tweet|
			@tweet_list <<  tweet['text']
		end
		@page += 1
	end
	slim :manage
end










