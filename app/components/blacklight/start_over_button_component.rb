# frozen_string_literal: true

module Blacklight
  class StartOverButtonComponent < Blacklight::Component
    def call
      link_to t('blacklight.search.start_over'), start_over_path, class: 'catalog_startOverLink btn btn-primary'
    end

    private

    # Always return the root path
    def start_over_path(_query_params = params)
      helpers.root_path
    end
  end
end
