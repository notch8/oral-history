class FullTextViewComponent < Blacklight::DocumentComponent
  def initialize(document:, document_index_view_type:, more:, highlight_page:)
    return if document.nil? # Skip if document is nil
    @document = document
    @document_index_view_type = document_index_view_type
    @more = more
    @highlight_page = highlight_page
  end
end
