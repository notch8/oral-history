module ApplicationHelper
  def split_multiple(options={})
    render 'shared/multiple', value: options[:value].uniq
  end

  def from_helper(attr, document)
    if document._source.present? && document._source[attr].present?
      document._source[attr].map do |child|
        JSON.parse(child)
      end
    end
  end

  def type_of_resource(document)
    if document._source["type_of_resource_t"] == nil
      type = "audio"
    else
      type = document._source["type_of_resource_t"][0]
    end
    type.downcase
  end

  def transcripts_from(document)
    from_helper "transcripts_json_t", document
  end

  def children_from(document)
    from_helper "children_t", document
  end

  def peaks_from(document)
    from_helper "peaks_t", document
  end

  def search_match(parsed_children, q)
    matches = []
    parsed_children.each do |child|
      match = {}
      regex = Regexp.new("\\b(#{Regexp.escape(q)})\\b", Regexp::IGNORECASE | Regexp::MULTILINE) if q.present?
      if regex  && regex =~ child['description_t']
        match['search_match'] = true
        match['highlighted_description'] = child['description_t'].gsub(regex, '<span class="label label-warning">\1</span>')
      else
        match['search_match'] = false
        match['highlighted_description'] = child['description_t']
      end
      matches << match
    end
    matches
  end

  def index_filter options={}
    "<span><p>#{ options[:value][0] }...</p></span>".html_safe
  end

  def highlightable_series_link(options={})
    link_to options[:value][0], root_path(f: {series_facet: options[:document]["series_t"]})
  end

  def link_parser(links)
    result = {}
    links.each do |link|
      parsed = JSON.parse(link)
      result[parsed[1]] = parsed[0]
    end
    return result
  end

  def allowed_links(links)
    links.reject {|name, value| name.match('Narrator') || name.match('TEI') if name.present? }
  end

  def allowed_links_present?(links)
    allowed_links(links).size > 0
  end

  def file_links(options = {})
    links = options[:value].map do |f|
      f = JSON.parse(f)

      link_to f[1], f[0], target: '_blank'
    end

    links.join('<br/>').html_safe
  end

  def audio_icon options={}
    "<span class='#{ options[:value][0] == "T" || options[:value][0] == true ? 'font-awesome-headphones' : 'font-awesome-no' }'></span>".html_safe
  end

  def audio_icon_with_text options={}
    if options == "false"
      "<span class='font-awesome-no style='margin-left: 1em;'></span>&nbsp;no".html_safe
    else
      "<span class='font-awesome-headphones' style='margin-left: 1em;'></span>&nbsp;yes".html_safe
    end
  end

  def narrator_image(document)
    thumbnail = document["links_t"].select { |str| str.match(/master.jpg/) } if document["links_t"]
    thumbnail_url = URI.extract(thumbnail.flatten.first).first if thumbnail && thumbnail.any?
    image = thumbnail_url.present? ? thumbnail_url : "/avatar.jpg"
  end


end
