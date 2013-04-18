require 'rubygems'
require 'sinatra'
require 'slim'
require 'multi_json'
require 'httparty'
require 'mongoid'

Mongoid.load!("mongoid.yml")

class Movie
  include Mongoid::Document
  field :mt, as: :movie_title, type: String
  field :tweets, type: Hash
  field :status_analysis, type: Boolean, default: false
end

class Stat
  include Mongoid::Document
  field :title, type: String 
  field :total_count, type: Integer
  field :stat_positive, type: Integer
  field :stat_negative, type: Integer
end

class Twitter
  include HTTParty
  base_uri 'search.twitter.com'

  def search(query, page)
    # The filters help to sanitize the list of tweets in the response
    filters = " -filter:links
                -t.co
                -#unacteurunfilm
                -'go'
                -'vais voir'
                -'va voir'

                '-RT"
    # The options for the HTTParty query
    @options = {:query => {:q => query + filters,
        :rpp => 100,
        :page => page,
        :lang => :fr,
        :result_type => :mixed}}

    # The Twitter search API query with help from HTTParty
    self.class.get("/search.json", @options)['results']
  end
end

get '/' do
  redirect '/manage'   # To do later : implement login form for admin
end

get '/manage' do
  @movie = Movie.all   # List all the movies in the database
  slim :manage
end

post '/query/new' do
  @title = "#{params[:query][:title]}" # Get the Query from the user
  @tweet_list = []                     # To store the tweets from the response
  @page = 1                            # To iterate multiple time the query
  twitter = Twitter.new

  # Iterate over a loop multiple times bound by the page number
  # The number or tweets for the query is determined by
  # (the number of pages) * (the number of result per page, up to 100)
  # Each iteration add the results of the new page to the hash to accumulate the tweets in the Hash
  while @page <= 3
    response = twitter.search(@title, @page)
    response.each do |tweet|
      @tweet_list << tweet['text']
    end
    @page += 1
  end

  # Create a new Movie document in the collection
  movie = Movie.new(:mt => @title, :tweets => @tweet_list)

  if movie.save
    redirect '/manage'
  else
    "Error saving list"
  end

  slim :manage
end

get '/delete/all' do
  # Destroy all the Movie documents in the collection
  collection = Movie.all
  if collection.delete
    redirect '/manage'
  else
    "Error delete all the movies"
  end
end

get '/results/delete' do
  # Destroy all the results of the analysis
  results = Stat.all
  if results.delete
    redirect '/manage'
  else
    "Error deleting the results"
  end
end
