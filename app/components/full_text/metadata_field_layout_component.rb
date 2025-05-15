# frozen_string_literal: true

module Blacklight
  class MetadataFieldLayoutComponent < Blacklight::Component
    with_collection_parameter :field
    renders_one :label
    renders_many :values, (lambda do |value: nil, &block|
      if @value_tag.nil?
        block&.call || value
      elsif block
        content_tag @value_tag, class: "#{@value_class} blacklight-#{@key}", &block
      else
        content_tag @value_tag, value, class: "#{@value_class} blacklight-#{@key}"
      end
    end)

    # @param field [Blacklight::FieldPresenter]
    def initialize(field:, value_tag: 'dd', label_class: 'sr-only', value_class: 'col-md-12')
      @field = field
      @key = @field.key.parameterize
      @label_class = label_class
      @value_tag = value_tag
      @value_class = value_class
    end
  end
end
