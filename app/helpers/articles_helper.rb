module ArticlesHelper

  # useful for highlighting attributes, when synchronizing articles
  def highlight_new(unequal_attributes, attribute)
    return unless unequal_attributes
    unequal_attributes.detect {|a| a == attribute} ? "background-color: yellow" : ""
  end

  def row_classes(article)
    classes = []
    classes << "unavailable" if !article.availability
    classes << "just-updated" if article.recently_updated && article.availability
    classes.join(" ")
  end

  # Flatten search params, used in import from external database
  def search_params
    return {} unless params[:search]
    Hash[params[:search].map { |k,v| [k, (v.is_a?(Array) ? v.join(" ") : v)] }]
  end

  # title attribute with extra article information
  def article_info_title(article)
    order_title = []
    order_title << Article.human_attribute_name(:manufacturer)+': ' + article.manufacturer unless article.manufacturer.to_s.empty?
    order_title << Article.human_attribute_name(:note)+': ' + article.note unless article.note.to_s.empty?
    order_title.join("\n")
  end

  # show icon with link to product information when available
  def article_info_icon(article, supplier=article.supplier)
    icon = "<i class='icon-info-sign'></i>".html_safe
    unless (url = article.info_url(supplier)).blank?
      link_to icon, url, target: '_blank'
    else
      icon
    end
  end

  # origin is shown as flag + title with details
  def article_origin(origin_or_article)
    origin = (origin_or_article.origin rescue origin_or_article)
    return if origin.blank?
    parts = origin.split /,\s*/
    country = WorldFlags.flag_code parts[-1]
    flag_list 16 do
      # TODO get full country name from WorldFlag and display that in title
      flag country, title: origin
    end
  end

end
