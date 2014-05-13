# Mention scope with ordergroups in PDFs
module FoodsoftMultishared
  module AddScopeToDocument

    module Articles
      def self.included(base) # :nodoc:
        base.class_eval do

          alias_method :foodsoft_multishared_orig_table, :table
          def table(rows, *args)
            rows.each_index do |i|
              row = rows[i]
              if i == 0
                rows[i] = row = row.dup # avoid updating i18n array
                s = Ordergroup.human_attribute_name :scope
              elsif row[0] == I18n.t('documents.order_by_groups.sum')
                s = nil
              else
                s = Ordergroup.find_by_name(row[0]).scope
              end
              row << s
            end
            rows[1..-2].sort_by! {|r| r[-1]}
            foodsoft_multishared_orig_table(rows, *args) do |table|
              table.column(-1).align = :right
              yield(table) if block_given?
            end
          end

        end
      end
    end

    module Groups
      def self.included(base) # :nodoc:
        base.class_eval do

          alias_method :foodsoft_multishared_orig_body, :body
          def body
            @ordergroups = Ordergroup.joins(:orders).where(orders: {id: @order}).select('distinct(groups.id)').select(:name).select(:price_markup_key).reorder('groups.scope, groups.name')
            foodsoft_multishared_orig_body
          end

          alias_method :foodsoft_multishared_orig_text, :text
          def text(s, options={})
            if g = Ordergroup.find_by_name(s)
              table [[s, g.scope]], width: 500 do |table|
                table.cells.borders = []
                table.cells.font_style = options[:style] if options[:style]
                table.cells.size = options[:size] if options[:size]
                table.column(0).align = :left
                table.column(1).align = :right
              end
            else
              foodsoft_multishared_orig_text(s, options)
            end
          end

        end
      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  OrderByArticles.send :include, FoodsoftMultishared::AddScopeToDocument::Articles
  MultipleOrdersByArticles.send :include, FoodsoftMultishared::AddScopeToDocument::Articles
  OrderByGroups.send :include, FoodsoftMultishared::AddScopeToDocument::Groups
  MultipleOrdersByGroups.send :include, FoodsoftMultishared::AddScopeToDocument::Groups
end
