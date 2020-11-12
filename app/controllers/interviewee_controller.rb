class IntervieweeController < ApplicationController

  include Blacklight::Catalog
  include Blacklight::Marc::Catalog

  configure_blacklight do |config|
    config.default_solr_params = {
      rows: 10,
    }
    config.index.title_field = 'title_display'
    config.index.display_type_field = 'format'

#    config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'

    config.add_facet_field 'interviewee_sort', label: 'Interviewee List', :query => {
                             :a => { label: 'A', fq: "interviewee_sort:/A.*/" },
                             :b => { label: 'B', fq: "interviewee_sort:/B.*/" },
                             :c => { label: 'C', fq: "interviewee_sort:/C.*/" },
                             :d => { label: 'D', fq: "interviewee_sort:/D.*/" },
                             :e => { label: 'E', fq: "interviewee_sort:/E.*/" },
                             :f => { label: 'F', fq: "interviewee_sort:/F.*/" },
                             :g => { label: 'G', fq: "interviewee_sort:/G.*/" },
                             :h => { label: 'H', fq: "interviewee_sort:/H.*/" },
                             :i => { label: 'I', fq: "interviewee_sort:/I.*/" },
                             :j => { label: 'J', fq: "interviewee_sort:/J.*/" },
                             :k => { label: 'K', fq: "interviewee_sort:/K.*/" },
                             :l => { label: 'L', fq: "interviewee_sort:/L.*/" },
                             :m => { label: 'M', fq: "interviewee_sort:/M.*/" },
                             :n => { label: 'N', fq: "interviewee_sort:/N.*/" },
                             :o => { label: 'O', fq: "interviewee_sort:/O.*/" },
                             :p => { label: 'P', fq: "interviewee_sort:/P.*/" },
                             :q => { label: 'Q', fq: "interviewee_sort:/Q.*/" },
                             :r => { label: 'R', fq: "interviewee_sort:/R.*/" },
                             :s => { label: 'S', fq: "interviewee_sort:/S.*/" },
                             :t => { label: 'T', fq: "interviewee_sort:/T.*/" },
                             :u => { label: 'U', fq: "interviewee_sort:/U.*/" },
                             :v => { label: 'V', fq: "interviewee_sort:/V.*/" },
                             :w => { label: 'W', fq: "interviewee_sort:/W.*/" },
                             :x => { label: 'X', fq: "interviewee_sort:/X.*/" },
                             :y => { label: 'Y', fq: "interviewee_sort:/Y.*/" },
                             :z => { label: 'Z', fq: "interviewee_sort:/Z.*/" }
                           }
    config.add_sort_field 'interviewee_sort asc, title_sort asc', label: 'Interviewee'
    config.add_index_field 'title_t', label: 'Title', highlight: true, solr_params: { :"hl.alternateField" => "dd" }
    config.add_index_field 'subject_t', label: 'Topic', helper_method: :split_multiple, highlight: true, solr_params: { :"hl.alternateField" => "dd" }
    config.add_index_field 'audio_b', label: 'Audio', highlight: true, solr_params: { :"hl.alternateField" => "dd" }, helper_method: 'audio_icon'
    config.add_facet_fields_to_solr_request!

    config.add_field_configuration_to_solr_request!

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


#  def index
#
#  end
end
