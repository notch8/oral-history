module ApplicationHelper
  def split_multiple(options={})
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field
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
end
