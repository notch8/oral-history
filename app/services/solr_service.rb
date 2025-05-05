require 'faraday'
require 'json'
require 'multipart/post'

class SolrService
  @@connection = false

  def self.connect
    @@connection = RSolr.connect(url: Blacklight.connection_config[:url])
    @@connection
  end

  def self.add(params)
    connect unless @@connection
    @@connection.add(params)
  end

  def self.commit
    connect unless @@connection
    @@connection.commit
  end

  def self.extract(params)
    connect unless defined?(@@connection) && @@connection
    path = params.delete(:path)

    puts "📤 Uploading PDF: #{path}"
    puts "📡 Posting to Solr at: #{Blacklight.connection_config[:url]}/update/extract"

    conn = Faraday.new(url: Blacklight.connection_config[:url]) do |faraday|
      faraday.request :multipart
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end

    file = Faraday::UploadIO.new(path, 'application/pdf')

    response = conn.post('update/extract') do |req|
      req.body = {
        file: file,
        extractOnly: true,
        extractFormat: 'text',
        wt: 'json'
      }
    end

    safe_body = response.body.to_s.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

    puts "🟢 Solr Response Status: #{response.status}"
    puts "🟢 Solr Response Preview (first 500 chars):"
    puts safe_body[0..500] + '...'

    response.success? ? JSON.parse(safe_body) : nil
  end

  def self.delete_by_id(id)
    connect unless @@connection
    @@connection.delete_by_id(id)
  end

  def self.remove_all
    connect unless @@connection
    @@connection.delete_by_query('*:*')
    @@connection.commit
  end

  def self.all_ids
    connect unless @@connection

    res = @@connection.get("select", params: { rows: 2_000_000_000, fl: 'id' })
    res&.[]('response')&.[]('docs')&.map { |v| v['id'] }
  end

  def self.all_records
    connect unless @@connection

    page_size = 1000
    cursor = 0

    res = @@connection.get 'select', params: { start: cursor, rows: page_size }
    remaining_records = res["response"]["numFound"].to_i

    res["response"]["docs"].each do |ref|
      yield(ref) if block_given?
      remaining_records -= 1
    end

    while remaining_records > 0
      res = @@connection.get 'select', params: { start: cursor, rows: page_size }

      res["response"]["docs"].each do |ref|
        yield(ref) if block_given?
        remaining_records -= 1
      end

      cursor += page_size
    end
  end

  def self.total_record_count
    connect unless @@connection
    res = @@connection.get 'select', params: { rows: 0 }
    res["response"]["numFound"].to_i
  end
end
