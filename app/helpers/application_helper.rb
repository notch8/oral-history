module ApplicationHelper
  def split_multiple(options={})
    options[:document] # the original document
    options[:field] # the field to render
    options[:value] # the value of the field
    render 'shared/multiple', value: options[:value].uniq
  end
end
