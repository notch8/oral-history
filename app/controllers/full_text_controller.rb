# frozen_string_literal: true
class FullTextController < ApplicationController

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog

  configure_blacklight do |config|

    config.default_solr_params = {
      rows: 5,
      :"hl" => true,
      :"hl.fl" => ["description_t", "transcripts_t"],
      :"hl.simple.pre" => "<span class='label label-warning'>",
      :"hl.simple.post" => "</span>",
      :"hl.snippets" => 30,
      :"hl.fragsize" => 200,
      :"hl.requireFieldMatch" => true,
      :"hl.maxAnalyzedChars" => -1
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_display'
    config.index.display_type_field = 'format'

    config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'language_facet', label: 'Language', limit: true
    config.add_facet_field 'series_facet', label: 'Series'
    config.add_facet_field 'audio_b', label: 'Has Media', helper_method: 'audio_icon_with_text'

    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'transcripts_t', label: 'Transcript', highlight: true, helper_method: :split_multiple
    config.add_index_field 'description_t', label: 'Description', highlight: true

    config.add_search_field 'all_fields', label: 'All Fields'

    config.add_search_field('title') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', label: 'Relevance'
    config.add_sort_field 'series_sort asc, title_sort asc', label: 'Series'
    config.add_sort_field 'interviewee_sort asc, title_sort asc', label: 'Interviewee'
    config.add_sort_field 'language_sort asc, title_sort asc', label: 'Language'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = false
    # config.autocomplete_path = 'suggest'

    config.add_field_configuration_to_solr_request!

    config.add_results_document_tool(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)
    config.add_show_tools_partial(:bookmark, partial: 'bookmark_control', if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)
    config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

  end

  # Override index method
  # get search results from the solr index
  def index
    #this is the number of rows to return (documents)
    params[:rows] = 1

    # highlight_page is what we want to use for our pagination ( or load_more option )
    # we start highlight page at 1 and it increments in the view
    @highlight_page = params[:highlight_page] || 1
    @highlight_page = @highlight_page.to_i

    # highlight count is how many highlights we are displaying on each page
    # initialize highlight_count to zero
    highlight_count = 0

    # results page is the page that solr sends back in the response.
    # this value currently increments based on the params[:rows] value
    # initialize results_page to start on page 1
    @results_page = 1

    # results_count is the number of documents returned
    # initializes results_count and sets the initial value to 1
    # this value ends up being the same as params[:rows]
    results_count = 1

    # document_list is the items we send to the presenter/view
    # initializes and sets to an empty array
    @document_list = []

    while(highlight_count < (50 * @highlight_page) && results_count > 0) do

      # page number sent from solr
      params[:page] = @results_page

      # gets the response and documents from params
      search_service = Blacklight::SearchService.new(config: blacklight_config, user_params: params)
      (@response, @documents) = search_service.search_results

      # these are docs returned in params, the number of docs returned is equal to the value of params[:rows]
      @document_list += @documents

      # setting the value to count of @documents, also params[:rows]
      results_count = @documents.size

      # this is an array of records with highlight matches on transcript_t and description_t
      # [ { highlighting: { doc: [transcript_t, description_t] } } ]
      highlights = @response['highlighting'].values

      # adds the total number of highlights in @response['highlighting'].values
      highlights.each { |t| highlight_count += t['transcripts_t'].count unless t['transcripts_t'].nil? }
      highlights.each { |t| highlight_count += t['description_t'].count unless t['description_t'].nil? }

      # increments the results page at end of the iteration
      #this should then make this page 2, the second group of params[:rows]
      @results_page += 1
    end

    @more = (results_count > 0)

    respond_to do |format|
      format.html do |html|
        if params[:partial]
          render partial: 'document_list', locals: { documents: @document_list }
        else
          store_preferred_view
        end
      end
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        @presenter = Blacklight::JsonPresenter.new(@response,
                                                   @document_list,
                                                   facets_from_request,
                                                   blacklight_config)
      end
      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  # Override to add highlighing to show
  def show
    @response, @document = fetch params[:id], {
      :"hl.q" => current_search_session.try(:query_params).try(:[], "q"),
      :df => blacklight_config.try(:default_document_solr_params).try(:[], :"hl.fl")
    }
    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end
end
