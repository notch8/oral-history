module ApplicationHelper
  def split_multiple(options={})
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field
    render 'shared/multiple', value: options[:value].uniq
  end

  def children_from(document)
    if document._source.present? && document._source["children_t"].present?
      document._source["children_t"].map do |child|
        JSON.parse(child)
      end
    end
  end
end
