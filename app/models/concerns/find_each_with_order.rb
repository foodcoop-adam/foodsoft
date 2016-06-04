# @see https://gist.github.com/virtualstaticvoid/8705533
module FindEachWithOrder
  def self.included(base)
    base.class_eval do

      def self.find_each_with_order(options = {})
        find_in_batches_with_order(options) do |records|
          records.each { |record| yield record }
        end
      end

      # NOTE: any limit() on the query is overridden with the batch size
      def self.find_in_batches_with_order(options = {})
        options.assert_valid_keys(:batch_size)

        relation = self

        start = 0
        batch_size = options.delete(:batch_size) || 1000

        relation = relation.limit(batch_size)
        records = relation.offset(start).to_a

        while records.any?
          records_size = records.size

          yield records

          break if records_size < batch_size

          # get the next batch
          start += batch_size
          records = relation.offset(start).to_a
        end
      end

    end
  end
end
