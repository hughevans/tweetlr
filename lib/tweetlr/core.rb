# encode: UTF-8
local_path=File.dirname(__FILE__)
require "#{local_path}/processors/twitter"
require "#{local_path}/processors/http"
require "#{local_path}/processors/photo_service"
require "#{local_path}/processors/tumblr"
require "#{local_path}/combinators/twitter_tumblr"
require "#{local_path}/log_aware"
require 'uri'

class Tweetlr::Core  
  include Tweetlr::LogAware
  def self.log
    Tweetlr::LogAware.log #TODO why doesn't the include make the log method accessible?
  end
  
  def initialize(args)
    initialize_logging(args[:loglevel])
    initialize_attributes(args)
    Tweetlr::LogAware.log.info "Tweetlr #{Tweetlr::VERSION} initialized. Ready to roll."
  end
  
  def self.crawl(config)
    log.debug "#{self}.crawl() using config: #{config.inspect}"
    twitter_config = prepare_twitter_config config
    tumblr_config = prepare_tumblr_config config
    twitter_config[:search_term] = URI::escape(twitter_config[:search_term]) if twitter_config[:search_term]
    log.info "starting tweetlr crawl..."
    response = {}
    response = Tweetlr::Processors::Twitter::lazy_search(twitter_config)
    if response
      process_response response, config
      # store the highest tweet id
      config[:since_id] = response['max_id']
    else
      log.error "twitter search returned no response. hail the failwhale!"
    end
    log.info "finished tweetlr crawl."
    return config
  end
private
  def initialize_attributes(args)
    @email = args[:tumblr_email]
    @password = args[:tumblr_password]
    @cookie = args[:cookie]
    @api_endpoint_twitter = args[:api_endpoint_twitter] || Tweetlr::API_ENDPOINT_TWITTER
    @api_endpoint_tumblr = args[:api_endpoint_tumblr] || Tweetlr::API_ENDPOINT_TUMBLR
    @whitelist = args[:whitelist]
    @shouts = args[:shouts]
    @update_period = args[:update_period] || Tweetlr::UPDATE_PERIOD
    @whitelist.each {|entry| entry.downcase!} if @whitelist
  end
  def initialize_logging(loglevel)
    log = Tweetlr::LogAware.log || Logger.new(STDOUT)
    if (Logger::DEBUG..Logger::UNKNOWN).to_a.index(loglevel)
      log.level = loglevel 
    else
      log.level = Logger::INFO
    end
    log.debug "log level set to #{log.level}"
    Tweetlr::LogAware.log=log
  end 
  def self.process_response(response, config)
    tweets = response['results']
    process_and_post tweets, config if tweets
  end
  def self.process_and_post(tweets, config)
    tweets.each do |tweet|
      tumblr_post = Tweetlr::Combinators::TwitterTumblr::generate_photo_post_from_tweet(tweet, {:whitelist => config[:whitelist], :embedly_key => config[:embedly_key], :group => config[:group]}) 
      if tumblr_post.nil? ||  tumblr_post[:source].nil?
        log.warn "could not get image source: tweet: #{tweet} --- tumblr post: #{tumblr_post.inspect}"
      else
        post_to_tumblr tumblr_post, config
      end
    end    
  end
  def self.post_to_tumblr(tumblr_post, config)
    log.debug "tumblr post: #{tumblr_post}"
    res = Tweetlr::Processors::Tumblr.post tumblr_post.merge(config)
    if res && res.code == "201"
      log.info "tumblr post created (tumblr response header: #{res.header}"
    elsif res
      log.warn "tumblr response: #{res.header} #{res.body}"
    else
      log.warn "there was no tumblr post response - most probably due to a missing oauth authorization"
    end
  end
  def self.prepare_twitter_config(config)
    config[:since_id] ||= config[:start_at_tweet_id]
    config[:terms] ||= config[:search_term]
    config[:results_per_page] ||= Tweetlr::TWITTER_RESULTS_PER_PAGE
    config[:result_type] ||= Tweetlr::TWITTER_RESULTS_TYPE
    config[:api_endpoint_twitter] ||= Tweetlr::API_ENDPOINT_TWITTER
    config
  end
  def self.prepare_tumblr_config(config)
    config[:tumblr_blog_hostname] ||= config[:group]
    config
  end
end
