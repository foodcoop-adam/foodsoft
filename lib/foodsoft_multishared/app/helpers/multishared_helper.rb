module MultisharedHelper
  # return foodcoop title from scope configuration
  def scope_title(scope, cfg)
    address = FoodsoftMultishared.address_line(cfg[:contact])
    append = []
    addons = []
    addons << cfg[:name] if cfg[:name].strip != FoodsoftConfig[:name].strip
    addons << cfg[:list_desc] if cfg[:list_desc]
    addons.map! do |a|
      content_tag(:div, h(a), style: 'color: grey; font-size: 12px; line-height: 12px;')
    end
    if defined? FoodsoftSignup and FoodsoftMultishared.signup_limit_reached?(scope, cfg)
      append << content_tag(:b, ' ('+I18n.t('multishared_signup.full')+')')
    end
   content_tag :div, h(address) + safe_join(append, ' ') + safe_join(addons), class: 'scope-title'
  end

  def scope_markers(scopes)
    Gmaps4rails.build_markers(scopes.to_a) do |(scope, cfg), marker|
      lat, lon = cfg[:contact]['lat'], cfg[:contact]['lon']
      next unless lat and lon
      marker.lat lat
      marker.lng lon
      marker.picture maps_marker_icon
      marker.json({id: scope, full: FoodsoftMultishared.signup_limit_reached?(scope, cfg)?'true':'false'})
    end.compact
  end

  # possible names are: waypoint-a waypoint-b waypoint-blue ad poi
  def maps_marker_icon(name='waypoint-a', text=nil, size=30)
    text = '•' if text == :dot
    url = "http://mt.google.com/vt/icon?psize=#{u size}&name=icons/spotlight/spotlight-#{u name}.png"
    url += "&font=fonts/arialuni_t.ttf&color=ff304C13&ax=43&ay=48&text=#{u text}" if text
    {url: url, width: 22, height: 40}
  end
end
