# Helpers for rendering trees
module FoodsoftRenderTreeHelper
  # `the_sortable_tree` renderer with block
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

  # @param collection [Enumberable<#id, #depth>] What to generate options for.
  # @option options [String, Symbol] :title Attribute to show.
  # @option options [Object] :selected Selected option.
  # @return [String] Options for select, indented by level.
  def nested_options(collection, options = {})
    title_method = options[:title] || 'title'
    options_for_select collection.map {|o| ["#{"\u202f"*4*o.depth}#{o.send title_method}", o.id]}, options[:selected]
  end
end
