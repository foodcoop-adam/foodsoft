
module FoodsoftProtectShared

  # show warning on included controllers
  module SharedArticle

    def self.included(base) # :nodoc:
      base.class_eval do
        after_find do |shared_article|
          if shared_article.price
            shared_article.price = SharedArticle.randprice(shared_article.price, shared_article.id)
            # just to be sure we don't overwrite it; you should use readonly db access anyway
            shared_article.readonly!
          end
        end
      end
    end

    # return 1.(1), 2.(2), etc.
    def self.repnum(i)
      (i < 9) ? i/9.0 : (1-1e-15)
    end

    # return random number with more or less the same order of magnitude
    def self.randmag(x, rnd = Random.new)
      return rnd.rand if not x or x == 0
      omag = (Math.log10(x) + rnd.rand(-10..10)/10.0).truncate
      #x = rnd.rand * 10**(omag+1)
      x = repnum(rnd.rand(1..9)) * 10**(omag+1)
    end

    # return random price
    # factor will be unique for each id until a restart
    def self.randprice(price, id)
      rnd = Random.new(@seed + id) # XXX perhaps not really secure ...
      randmag(price*100, rnd).truncate / 100.0
    end

    @seed = Random.new_seed

  end

end

# now patch desired controllers to include this
ActiveSupport.on_load(:after_initialize) do
  SharedArticle.send :include, FoodsoftProtectShared::SharedArticle
end
