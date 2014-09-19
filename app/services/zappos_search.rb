require 'open-uri'

class ZapposSearch
  API_KEY = "52ddafbe3ee659bad97fcce7c53592916a6bfd73".freeze
  URL = "https://api.zappos.com/Search".freeze
  NEW_PRODUCT_URL = "#{URL}?filters={\"isNew\":\"true\"}&key=#{API_KEY}&sort={\"price\":\"asc\"}".freeze
  LIMIT = 100.freeze

  class << self
    def new_products
      JSON.parse(REDIS.get('new_products')) || get_all_new_products
    end

    # We just want to gift new products dont we? :D
    def get_all_new_products
      products_data = parse_data(NEW_PRODUCT_URL)
      total_new_products_count = products_data["totalResultCount"].to_i

      products = []
      # Due to the 100 products limit per query, we will loop through all the
      # pages to obtain the new products and store them in an array.
      ((total_new_products_count.to_f / LIMIT).ceil).times do |n|
        products << parse_data("#{NEW_PRODUCT_URL}&limit=#{LIMIT}&page=#{n}")["results"]
      end

      REDIS.set('new_products', products.flatten.compact.to_json)
    end

    private

    def parse_data(url)
      JSON.parse(open(URI.encode(url)).read)
    end
  end
end
