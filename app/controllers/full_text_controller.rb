# frozen_string_literal: true
class FullTextController < ApplicationController

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog

  configure_blacklight do |config|
    
    config.default_solr_params = {
      rows: 3,
      :"hl" => true,
      :"hl.fl" => ["description_t", "transcripts_t"],
      :"hl.simple.pre" => "<span class='label label-warning'>",
      :"hl.simple.post" => "</span>",
      :"hl.snippets" => 50,
      :"hl.fragsize" => 300,
      :"hl.maxAnalyzedChars" => -1
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'title_display'
    config.index.display_type_field = 'format'
    
    config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
    config.add_facet_field 'language_facet', label: 'Language', limit: true
    config.add_facet_field 'series_facet', label: 'Series'
    config.add_facet_field 'audio_b', label: 'Has Audio', helper_method: 'audio_icon_with_text'

    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field 'description_t', label: 'Description', highlight: true 
    config.add_index_field 'transcripts_t', label: 'Transcript', highlight: true, helper_method: :split_multiple
    
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
