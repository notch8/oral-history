# frozen_string_literal: true

class FullTextController < ApplicationController
  include Blacklight::Catalog
  include Blacklight::Marc::Catalog

  configure_blacklight do |config|
    config.full_width_layout = true
    config.index.document_component = FullText::DocumentComponent
    config.default_solr_params = {
      rows: 1, # default number of results
      hl: true,
      'hl.fl': ['transcripts_t'],
      'hl.simple.pre': "<span class='label label-warning'>",
      'hl.simple.post': "</span>",
      'hl.snippets': 30,
      'hl.fragsize': 200,
      'hl.requireFieldMatch': true,
      'hl.maxAnalyzedChars': -1
    }

    config.index.title_field = 'title_display'
    config.index.display_type_field = 'format'

    config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'language_facet', label: 'Language', limit: true
    config.add_facet_field 'series_facet', label: 'Series'
    config.add_facet_field 'audio_b', label: 'Has Media', helper_method: 'audio_icon_with_text'
    config.add_facet_fields_to_solr_request!

    config.add_index_field 'transcripts_t', label: 'Transcript', highlight: true, helper_method: :split_multiple

    config.add_search_field 'transcripts_t', label: 'Transcripts'
    config.add_search_field('title') do |field|
      field.solr_parameters = { 'spellcheck.dictionary': 'title' }
      field.solr_local_parameters = { qf: '$title_qf', pf: '$title_pf' }
    end

    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', label: 'Relevance'

    config.spell_max = 5
    config.autocomplete_enabled = false
    config.add_field_configuration_to_solr_request!

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')
  end

  def index
    begin
      OralHistoryItem.index_logger.info "🟢 FullText Search Params: #{params.inspect}"

      params[:rows] = 1

      @highlight_page = params[:highlight_page].presence&.to_i || 1
      highlight_count = 0
      @results_page = 1
      results_count = 1
      @document_list = []
      @response = nil

      while highlight_count < (50 * @highlight_page) && results_count.positive?
        params[:page] = @results_page
        search_service = Blacklight::SearchService.new(config: blacklight_config, user_params: params)
        current_response = search_service.search_results

        @response ||= current_response
        documents = current_response.documents || []
        @document_list.concat(documents)
        results_count = documents.size

        highlights = current_response['highlighting'].values
        highlights.each do |t|
          snippets = t['transcripts_t']
          if snippets.is_a?(Array)
            highlight_count += snippets.count
            # highlight_count += Array(snippets).count
          else
            if Rails.env.development? || Rails.env.test?
              OralHistoryItem.index_logger.warn "🟡 Unexpected value for highlight snippet: #{snippets.inspect} (#{snippets.class})"
            end
          end
        end

        @results_page += 1
      end

      @more = results_count.positive?

      respond_to do |format|
        format.html do
          if params[:partial]
            render_document_index_with_view_component(@response.documents)
          else
            render :index
          end
        end

        # format.html do
        #   if params[:partial]
        #     render_document_index(
        #       documents: @response.documents,
        #       document_component: FullText::DocumentComponent,
        #       configuration: blacklight_config
        #     )
        #   else
        #     render :index
        #   end
        # end
        format.rss  { render layout: false }
        format.atom { render layout: false }
        format.json do
          @presenter = Blacklight::JsonPresenter.new(@response, @document_list, facets_from_request, blacklight_config)
        end
        additional_response_formats(format)
        document_export_formats(format)
      end

    rescue => e
      OralHistoryItem.index_logger.error "🛑 FullText#index error: #{e.class} - #{e.message}"
      OralHistoryItem.index_logger.error e.backtrace.join("\n")
      render plain: "Error: #{e.class} - #{e.message}", status: 500
    end
  end

  def show
    @response, @document = fetch params[:id], {
      hl_q: current_search_session&.dig("query_params", "q"),
      df: blacklight_config.default_document_solr_params&.dig(:'hl.fl')
    }

    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end
end
