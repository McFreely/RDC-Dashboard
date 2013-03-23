require 'rubygems'
require 'sinatra'
require 'slim'
require 'multi_json'
require 'httparty'
require 'mongoid'

Mongoid.load!("mongoid.yml")

# DB = Mongo::Connection.db('MovieList', :pool_size => 5, :timeout => 5)

class Movie
	include Mongoid::Document
	field :mt, as: :movie_title, type: String
	field :tweets, type: Hash
	field :status_analysis, type: Boolean, default: false
end

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

		@options = {:query => {:q => query + filters, :rpp => 10,
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
	@movie = Movie.all
	slim :manage
end

post '/query/new' do
	@title = "#{params[:query][:title]}"
	@tweet_list = []
	@page = 1
	twitter = Twitter.new
	while @page <= 3
		response = twitter.search(@title, @page)
		response.each do |tweet|
			@tweet_list << tweet['text']
		end
		@page += 1
	end
	movie = Movie.new(:mt => @title, :tweets => @tweet_list)
	if movie.save
		redirect '/manage'
	else
		"Error saving list"
	end
	slim :manage
end

get '/delete/all' do
	db = Movie.all
	if db.delete
		redirect '/manage'
	else
		"Error delete all the movies"
	end
end







