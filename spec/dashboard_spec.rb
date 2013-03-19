require_relative '../dashboard.rb'
require 'rack/test'
require 'webrat'

set :environment, :test

def app
	Sinatra::Application
end

include Rack::Test::Methods
include Webrat::Methods
include Webrat::Matchers

describe 'Dashboard' do
	it "should redirect / to /manage" do
		get '/'
		last_response.should be_redirect; follow_redirect!
		last_request.url.should include('/manage')
	end
end


describe 'views/layout.slim' do
    before(:all) do
  		get '/manage'
    end

    it "should have a valid head section" do
	    last_response.should have_selector('head')
	    last_response.should have_selector('meta')
	    last_response.should have_selector('link')
    end
    it "should have a body" do
	    last_response.should have_selector('body')
    end
    it "should have a footer" do
      	last_response.should have_selector('footer')
    end

	it "should have a page title" do
	    last_response.should have_selector('title', :content =>'Republique Democratique du Cinema')
	end
end

describe 'views/manage.slim' do
	it "should have a div#welcome, with a link" do
		get '/manage'
		last_response.should have_selector('div#welcome') do |div|
			div.should contain('Dashboard')
			div.should have_selector('a')
		end
	end

  	it "should have a div#query" do
  	  	get '/manage'
  	  	last_response.should have_selector('div#query')
  	end

  	it "should have an input form for querying twiter" do
	  	get '/manage'
	  	last_response.should have_selector('form#query')
	  	last_response.should have_selector('input#title')
	  	last_response.should have_selector('input#submit')
	end
end

describe '/query' do
	it "should post " do
		title = "kill bill"
		post '/query/new', {:query => {:title => title}}
		last_response.should be_ok
	end
end