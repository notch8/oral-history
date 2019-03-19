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
      :"hl.requireFieldMatch" => true,
      :"hl.snippets" => 50,
      :"hl.fragsize" => 200
    }

    config.default_document_solr_params = {
     #  qt: 'document',
     ## These are hard-coded in the blacklight 'document' requestHandler
     # fl: '*',
     # rows: 1,
     # q: '{!term f=id v=$id}'
      :"hl" => true,
      :"hl.fragsize" => 0,
      :"hl.preserveMulti" => true,
      :"hl.fl" => "biographical_t, subject_t, description_t, person_present_t, place_t, supporting_documents_t, interviewer_history_t, process_interview_t, type_of_resource_display, audio_b, extent_display, language_t, author_t, interviewee_t, title_t, subtitle_t, series_t, links_t",
      :"hl.simple.pre" => "<span class='label label-warning'>",
      :"hl.simple.post" => "</span>",
      :"hl.alternateField" => "dd"
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
    config.add_index_field 'transcripts_t', label: 'Transcript', highlight: true, helper_method: :split_multiple
    config.add_index_field 'description_t', label: 'Description', highlight: true, helper_method: :split_multiple

    
    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field 'subtitle_t', label: 'Subtitle', highlight: true
    config.add_show_field 'series_t', label: 'Series', link_to_search: "series_facet", highlight: true, helper_method: 'highlightable_series_link'
    config.add_show_field 'subject_t', label: 'Topic', helper_method: :split_multiple, highlight: true
    config.add_show_field 'contributor_display', label: 'Interviewer', highlight: true
    config.add_show_field 'author_t', label: 'Interviewer', highlight: true
    config.add_show_field 'interviewee_t', label: 'Interviewee', highlight: true
    config.add_show_field 'description_t', label: 'Description', highlight: true, helper_method: :split_multiple
    config.add_show_field 'person_present_t', label: 'Persons Present', highlight: true
    config.add_show_field 'place_t', label: 'Place Conducted', highlight: true
    config.add_show_field 'supporting_documents_t', label: 'Supporting Documents', highlight: true
    config.add_show_field 'interviewer_history_t', label: 'Interviewer Background and Preparation', highlight: true
    config.add_show_field 'process_interview_t', label: 'Processing of Interview', highlight: true
    config.add_show_field 'publisher_display', label: 'Publisher', highlight: true
    config.add_show_field 'pub_date', label: 'Date', highlight: true
    config.add_show_field 'extent_display', label: 'Length / Pages', highlight: true
    config.add_show_field 'language_t', label: 'Language'
    config.add_show_field 'coverage_display', label: 'Period Covered', highlight: true
    config.add_show_field 'rights_display', label: 'Copyright', highlight: true
    config.add_show_field 'audio_b', label: 'Audio', helper_method: 'audio_icon'
    config.add_show_field 'links_t', label: 'Files', helper_method: 'file_links'
    config.add_show_field 'abstract_t', label: 'Series Statement'

    config.add_search_field 'all_fields', label: 'All Fields'


    
    config.add_search_field('title') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }
      field.solr_local_parameters = {
        qf: '$title_qf',
        pf: '$title_pf'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
      field.solr_local_parameters = {
        qf: '$author_qf',
        pf: '$author_pf'
      }
    end

    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as
    # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    config.add_search_field('subject') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      field.qt = 'search'
      field.solr_local_parameters = {
        qf: '$subject_qf',
        pf: '$subject_pf'
      }
    end


    config.add_search_field('biographical') do |field|
      field.solr_parameters = { :'spellcheck.dictionary' => 'biographical' }
      field.solr_local_parameters = {
        qf: '$biographical_qf',
        pf: '$biographical_pf'
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
