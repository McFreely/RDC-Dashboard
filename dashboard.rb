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
  field :movie_poster, type: String
  field :trailer, type: String
  field :release_date, type: String, default: '2013'
  field :director, type: String
  field :runtime, type: String
  field :plot, type: String
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
                -RT"
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
  slim :manage do
    slim :empty
  end
end

get '/manage/:title' do
  @movie = Movie.all
  @title =  "#{params[:title]}"
  @movie_tweets = Movie.where(mt: "#{params[:title]}")
  slim :manage do
    slim :tweets
  end
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
  while @page <= 15
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

get '/manage/edit/:title' do
  # Show the infos for the movie selected
  @movie = Movie.all
  @title = "#{params[:title]}"
  @movie_infos = Stat.where(title: "#{params[:title]}")
  slim :manage do
    slim :edit
  end
end

put '/manage/edit/:title' do
  title = "#{params[:title]}"

  #create a hash with only the values to update
  edit = params[:edit].delete_if {|key, value| value.empty?}

  stat = Stat.where(title: title).update(edit)

  redirect to("/manage/edit/#{title}")

  slim :manage do
    slim :edit
  end
end

get '/delete/:title' do
  # Destroy the movie and the associated tweets
  movie = Movie.where(mt: "#{params[:title]}")
  if movie.delete
    redirect '/manage'
  else
    "Error while deleting document"
  end
end

get '/results/delete' do
  # Destroy all the results of the analysis
  movie = Movie.all
  results = Stat.all
  if results.delete
    movie.set(:status_analysis, false)
    redirect '/manage'
  else
    "Error deleting the results"
  end
end
