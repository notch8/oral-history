module FullText
  class DocumentComponent < Blacklight::DocumentComponent
    def before_render
      super

      set_slot(:title) do
        helpers.link_to @presenter.heading, url_for_document
      end
    end

    def highlight_snippets
      highlighting = helpers.controller.instance_variable_get(:@response)&.response&.dig('highlighting')
      return [] unless highlighting.is_a?(Hash)

      snippets = highlighting[@document.id]&.fetch('transcripts_t', [])
      Array(snippets).compact_blank
    rescue => e
      # Log only in development or debug mode
      OralHistoryItem.index_logger.debug("Highlight error for #{@document.id}: #{e.message}") if Rails.env.development?
      []
    end

    private

    def url_for_document
      helpers.search_state.url_for_document(@document)
    rescue
      helpers.url_for(controller: 'catalog', action: 'show', id: @document.id)
    end
  end
end
