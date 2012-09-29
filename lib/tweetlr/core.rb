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
    log = Logger.new(STDOUT)
    if (Logger::DEBUG..Logger::UNKNOWN).to_a.index(args[:loglevel])
      log.level = args[:loglevel] 
    else
      log.level = Logger::INFO
    end
    log.debug "log level set to #{log.level}"
    Tweetlr::LogAware.log=log
    
    @email = args[:tumblr_email]
    @password = args[:tumblr_password]
    @cookie = args[:cookie]
    @api_endpoint_twitter = args[:api_endpoint_twitter] || Tweetlr::API_ENDPOINT_TWITTER
    @api_endpoint_tumblr = args[:api_endpoint_tumblr] || Tweetlr::API_ENDPOINT_TUMBLR
    @whitelist = args[:whitelist]
    @shouts = args[:shouts]
    @update_period = args[:update_period] || Tweetlr::UPDATE_PERIOD
    @whitelist.each {|entry| entry.downcase!} if @whitelist
    log.info "Tweetlr #{Tweetlr::VERSION} initialized. Ready to roll."
  end
  
  def self.crawl(config)
    log.debug "#{self}.crawl() using config: #{config.inspect}"
    twitter_config = {
      :since_id => config[:since_id] || config[:start_at_tweet_id],
      :search_term => config[:terms] || config[:search_term] ,
      :results_per_page => config[:results_per_page] || Tweetlr::TWITTER_RESULTS_PER_PAGE,
      :result_type => config[:result_type] || Tweetlr::TWITTER_RESULTS_TYPE,  
      :api_endpoint_twitter => config[:api_endpoint_twitter] || Tweetlr::API_ENDPOINT_TWITTER
    }
    tumblr_config = { :tumblr_oauth_access_token_key => config[:tumblr_oauth_access_token_key],
                      :tumblr_oauth_access_token_secret => config[:tumblr_oauth_access_token_secret],
                      :tumblr_oauth_api_key => config[:tumblr_oauth_api_key],
                      :tumblr_oauth_api_secret => config[:tumblr_oauth_api_secret],
                      :tumblr_blog_hostname => config[:tumblr_blog_hostname] || config[:group]
                    }
      
    twitter_config[:search_term] = URI::escape(twitter_config[:search_term]) if twitter_config[:search_term]
    log.info "starting tweetlr crawl..."
    response = {}
    response = Tweetlr::Processors::Twitter::lazy_search(twitter_config)
    if response
      tweets = response['results']
      if tweets
      tweets.each do |tweet|
        tumblr_post = Tweetlr::Combinators::TwitterTumblr::generate_photo_post_from_tweet(tweet, {:whitelist => config[:whitelist], :embedly_key => config[:embedly_key], :group => config[:group]}) 
        if tumblr_post.nil? ||  tumblr_post[:source].nil?
          log.warn "could not get image source: tweet: #{tweet} --- tumblr post: #{tumblr_post.inspect}"
        else
          log.debug "tumblr post: #{tumblr_post}"
          res = Tweetlr::Processors::Tumblr.post tumblr_post.merge(tumblr_config)
          log.debug "tumblr response: #{res}"
          if res.code == "201"
            log.info "tumblr post created (tumblr response: #{res.header} #{res.body}"
          else
            log.warn "tumblr response: #{res.header} #{res.body}"
          end
        end
       end
        # store the highest tweet id
        config[:since_id] = response['max_id']
      end
    else
      log.error "twitter search returned no response. hail the failwhale!"
    end
    log.info "finished tweetlr crawl."
    return config
  end  
end