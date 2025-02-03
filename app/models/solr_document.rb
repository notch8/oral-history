# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document

  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Marc::DocumentExtension) do |document|
    document.key?( :marc_display  )
  end

  field_semantics.merge!(
    :title => "title_display",
    :author => "author_display",
    :interviewee => "interviewee_display",
    :language => "language_facet",
    :format => "format"
  )

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  # SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  # SolrDocument.use_extension(Blacklight::Document::Sms)


  # remove the lines below from your SolrDocument. If you have customized the emails or sms that you send to users, you can recreate those customizations by updating email_fields or sms_fields configurations in your catalog controller and/or subclassing MetadataFieldPlainTextLayoutComponent. See PR #2803 for more details.
  #  # Email uses the semantic field mappings below to generate the body of an email.
  #  SolrDocument.use_extension(Blacklight::Document::Email)

  #  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  #  SolrDocument.use_extension(Blacklight::Document::Sms) 


  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
end