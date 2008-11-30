require 'rubygems'
require 'hpricot'
require 'open-uri'

class Spiderz
  
  #root should be like http://www.google.com (i.e. with http://)
  def initialize(root)
    @crawled = {}
    @root = root

    @success = Proc.new { |url, doc| puts "Successfully read url: #{url}" }
    @failure = Proc.new { |url| puts "failure to read/parse url: #{url}" }
    @started = Proc.new { |url| puts "Started crawling from url: #{url}" }
    @completed = Proc.new { |url| puts "Crawling complete" }

    @skip = Proc.new do |href|
      !href || (external?(href) || mail?(href) || bookmark?(href))
    end
  end

  def crawl(url)
    @started.call(url)
    
    @to_crawl = [url]
  
    while(@to_crawl.length > 0)
      @to_crawl += page_links(@to_crawl.shift)
    end
  
    @completed.call(url)
  end
  
  def external? href
    href.match("[a-z]+://") && !href.match(@root)
  end
  
  def bookmark? href
    href.match(/^#/)
  end
  
  def mail? href
    href.match("mailto")
  end

  def started &action
    @started = action 
  end

  def completed &action
    @completed = action 
  end

  def failure &action
    @failure = action
  end

  def success &action
    @success = action
  end

  def skip &action
    @skip = action
  end

  def page_links url
    #puts url
    return [] if @crawled[url]

    @crawled[url] = true
    
    begin
      doc = Hpricot(open(@root+url))
    rescue
      @failure.call(url)
      return []
    end
    
    @success.call(url, doc)
    
    links = doc/"a" #find links

    urls = links.map do |a|
      a.attributes["href"]
    end    
    
    urls.delete_if do |url| 
      @crawled[url] || @skip.call(url)
    end
    
    urls
  end

end


