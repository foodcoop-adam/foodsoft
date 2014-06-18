# Helpers for rendering trees
module FoodsoftRenderTreeHelper
  # `the_sortable_tree` renderer
  module Block
    class Render
      class << self
        attr_accessor :h, :options

        def render_node(h, options)
          @h, @options = h, options

          node = options[:node]
          block = options[:content]
          children = options[:children]
          block.yield node, children
        end
      end
    end
  end
end
