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
      if regex &&  regex =~ child['description_t']
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

  def highlight_transcripts(parsed_transcripts, q)
    highlighted_transcripts = []
    parsed_transcripts.each do |child|
      regex = Regexp.new("\\b(#{Regexp.escape(q)})\\b", Regexp::IGNORECASE | Regexp::MULTILINE) if q.present?
      if regex && regex =~ child['transcript_t']
        child['search_match'] = true
        child['highlighted_transcript'] = child['transcript_t'].gsub(regex, '<span class="label label-warning">\1</span>')
      else
        child['search_match'] = false
        child['highlighted_transcript'] = child['transcript_t']
      end
      highlighted_transcripts << child
    end
    highlighted_transcripts
  end

  def index_filter options={}
    "#{ options[:value][0].truncate(300)}".html_safe
  end

  def highlightable_series_link(options={})
    link_to options[:value][0], root_path(f: {series_facet: options[:document]["series_t"]})
  end

  def link_parser(links)
    result = {}
    count = 1
    links.reverse.each do |link|
      parsed = JSON.parse(link)
      key = parsed[1]
      if key == 'Interview Full Transcript (PDF)'
        if result.has_key? key
          count += 1
          new_key = "Interview Full Transcript - #{count} (PDF)"
          result[new_key] = parsed[0]
        else
          result[key] = parsed[0]
        end
      else
        result[key] = parsed[0]
      end
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
    if "#{ options[:value][0] }".html_safe == "true"
      "<span class='font-awesome-headphones'></span>".html_safe
    else
      "<span class='font-awesome-no'></span>".html_safe
    end
  end

  def audio_icon_with_text options={}
    if "#{ options }".html_safe == "true"
      "<span class='font-awesome-headphones'></span>&nbsp;yes".html_safe
    else
      "<span class='font-awesome-no'></span>&nbsp;no".html_safe
    end
  end

  def narrator_image(document)
    thumbnail = document["links_t"].select { |str| str.match(/master.jpg/) } if document["links_t"]
    thumbnail_url = URI.extract(thumbnail.flatten.first).first if thumbnail && thumbnail.any?
    image = thumbnail_url.present? ? thumbnail_url : "/avatar.jpg"
  end


end
