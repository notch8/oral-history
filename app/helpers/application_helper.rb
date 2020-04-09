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

  def transcripts_from(document)
    from_helper "transcripts_json_t", document
  end

  def children_from(document)
    from_helper "children_t", document
  end

  def peaks_from(document)
    from_helper "peaks_t", document
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

  def no_images(links)
    links.reject {|name, value| name.match('Narrator') if name.present? }
  end

  def not_only_images?(links)
    no_images(links).size > 0
  end

  def file_links(options = {})
    links = options[:value].map do |f|
      f = JSON.parse(f)

      link_to f[1], f[0], target: '_blank'
    end

    links.join('<br/>').html_safe
  end

  def audio_icon options={}
    "<span class='glyphicon #{ options[:value][0] == "T" || options[:value][0] == true ? 'glyphicon-headphones' : 'glyphicon-ban-circle' }'></span>".html_safe
  end

  def audio_icon_with_text options={}
    if options == "false"
      "<span class='glyphicon glyphicon-ban-circle' style='margin-left: 1em;'></span>&nbsp;no".html_safe
    else
      "<span class='glyphicon glyphicon-headphones' style='margin-left: 1em;'></span>&nbsp;yes".html_safe
    end
  end

  def narrator_image(document)
    thumbnail = document["links_t"].select { |str| str.match(/master.jpg/) } if document["links_t"]
    thumbnail_url = URI.extract(thumbnail.flatten.first).first if thumbnail && thumbnail.any?
    image = thumbnail_url.present? ? thumbnail_url : "/avatar.jpg"
  end


end
