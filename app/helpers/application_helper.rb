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
end
