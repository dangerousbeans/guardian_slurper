
# $: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'nowa_api'
require 'guardian-content'

# Load articles from the guardian API and put them on ingenia


GUARDIAN_CONTENT_API_KEY = "DERPDERP"
INGENIAPI_API_KEY = "SECRET"

ENDPOINT = "http://api.ingeniapi.com/train"


#
# Setup
#

# Set API key to the test user for this gem
Nowa::Api.api_key = INGENIAPI_API_KEY



articles = GuardianContent::Content.search("", :select => {:tags => :all, :fields => [:title, :body]})


articles.each do |article|
  puts "=========================="
	puts article.title

  tag_sets = {}
  tags = article.tags.each do |t| 
    tag_sets[t[:type]] = [] if tag_sets[t[:type]].nil?
    tag_sets[t[:type]] << t[:id] unless tag_sets[t[:type]].include?(t[:id])
  end

  puts tag_sets

  text = article.title
  url = article.url

  # response = RestClient.post ENDPOINT, :api_key => INGENIAPI_API_KEY, :text => text, :tag_sets => tag_sets.to_json
  response = RestClient.post ENDPOINT, :api_key => INGENIAPI_API_KEY, :url => url, :text => text, :tag_sets => tag_sets.to_json

  puts response
end