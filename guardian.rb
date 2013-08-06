
# $: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'nowa_api'
require 'guardian-content'
require 'yaml'

# Load articles from the guardian API and put them on ingenia

CONFIG = YAML.load_file("config/apis.yml") unless defined? CONFIG

#
# Setup
#
class Guardian
  def initalize
    # Set API key to the test user for this gem
    Nowa::Api.api_key = CONFIG['INGENIAPI_API_KEY']
  end

  def read_results results

    results.each do |article|
      # basic info
      title = article['webTitle']
      text = article['fields']['body']

      # tags
      article_tags = article['tags']

      tag_sets = {}
      
      tags = article_tags.each do |t| 
        tag_sets[t['type']] = [] if tag_sets[t['type']].nil?
        tag_sets[t['type']] << t['id'] unless tag_sets[t['type']].include?(t['id'])
      end

      # puts title
      # puts tag_sets

      RestClient.post CONFIG['ENDPOINT'], :api_key => CONFIG['INGENIAPI_API_KEY'], :text => text, :tag_sets => tag_sets.to_json do |ingenia_response|
        puts ingenia_response
      end

    end
  end

  def handle_response response
    json_response = JSON.parse(response)
    json_response = json_response['response']

    pages = json_response['pages']
    current_page = json_response['currentPage']

    puts "Page #{current_page}/#{pages}"

    # handle this pages results
    read_results json_response['results']

    if current_page < pages
      return load(current_page + 1)
    end
  end

  # Load results from the guardian API
  def load page=1
    RestClient.get CONFIG['GUARDIAN_API'], :params => { 
          :format => 'json', 
          :'show-fields' => 'body', 
          :'show-tags' => 'all',
          :'from-date' => '2010-01-01',
          :'to-date' => '2011-01-01',
          :page => page,
          :'api-key' => CONFIG['GUARDIAN_CONTENT_API_KEY']
        } do |response|

      return handle_response response
    end
  end
end


g = Guardian.new
g.load