require 'hpricot'
require 'open-uri'

class Spider
  
  #root should be like http://www.google.com (i.e. with http://)
  def initialize root
    @cache = {}
    @to_spider = []
    @root = root
    @html_pages = {}
  end

  def spider url
    @to_spider = [url]
    spider_loop
  
    @html_pages.each do |url, html| 
      if block_given?
        yield(url, html)
      else
        puts url
      end
    end
  end

  def spider_loop 
    new_links = []
    while(@to_spider.length > 0)
      new_links = get_links_from_url(@to_spider.shift)
      @to_spider += new_links
    end
  end
  
  def external? href
    href.match("http://") && !href.match(@root)
  end
  
  def bookmark? href
    href.match(/^#/)
  end
  
  def mail? href
    href.match("mailto")
  end
  
  def skip?(href)
    !href || ( @cache[href] || external?(href) || mail?(href) || bookmark?(href))
  end

  def get_links_from_url url
    #puts url
    return [] if @cache[url]
    begin
      doc = Hpricot(open(@root+url))
    rescue
      puts "skipping: #{url}"
      @cache[url] = true
      return []
    end
    @cache[url] = true
    
    @html_pages[url] = doc
    
    links = doc/"a" #find links
    
    links.delete_if do |a| 
      skip? a.attributes["href"]
    end
    
    links.map do |a|
      a.attributes["href"]
    end
  end

end

