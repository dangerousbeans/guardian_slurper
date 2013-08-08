
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
      title = article['fields']['headline']
      summary = article['fields']['standfirst']
      body = article['fields']['body']

      text = "#{title} #{body} #{summary}"

      # tags
      article_tags = article['tags']

      tag_sets = {}
      
      tags = article_tags.each do |t| 
        tag_set_name = t['type']
        next unless tag_set_name == "keyword" # only record the keyword tags

        tag_sets[tag_set_name] = [] if tag_sets[tag_set_name].nil?
        tag_sets[tag_set_name] << t['id'] unless tag_sets[tag_set_name].include?(t['id'])
      end

      
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

    # handle this pages results and save them to ingenia
    read_results json_response['results']

    return pages
  end

  # Load results from the guardian API
  def load

    page = 1
    pages = 0

    loop do
      # until done
      RestClient.get CONFIG['GUARDIAN_API'], :params => { 
            :format => 'json', 
            :'show-fields' => 'headline,body,standfirst', 
            :'show-tags' => 'all',
            :tag => '(type/article|type/minutebyminute),publication/theguardian', # only articles | minutebyminute published by the guardian
            :'from-date' => '2013-01-01',
            :'to-date' => '2013-08-08',
            :page => page,
            :'api-key' => CONFIG['GUARDIAN_CONTENT_API_KEY']
          } do |response|

        pages = handle_response(response)
      end

      # stop
      break if page == pages
       
      page = page + 1 
    end
  end
end


g = Guardian.new
g.load