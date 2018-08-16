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
    from_helper "transcripts_t", document
  end

  def children_from(document)
    from_helper "children_t", document
  end

  def highlightable_series_link(options={})
    link_to options[:value][0], root_path(f: {series_facet: options[:document]["series_t"]})
  end

  def file_links(options = {})
    links = options[:value].map do |f|
      f = JSON.parse(f)

      link_to f[1], f[0], target: '_blank'
    end

    links.join('<br/>').html_safe
  end

  def audio_icon options={}
    "<dd class='blacklight-audio_b'><span class='glyphicon #{ options[:value][0] == "T" || options[:value][0] == true ? 'glyphicon-headphones' : 'glyphicon-ban-circle' }'></span></dd>".html_safe
  end

  def audio_icon_with_text options={}
    if options == "false"
      "<span class='glyphicon glyphicon-ban-circle' style='margin-left: 1em;'></span>&nbsp;false".html_safe
    else
      "<span class='glyphicon glyphicon-headphones' style='margin-left: 1em;'></span>&nbsp;true".html_safe
    end
  end
end
