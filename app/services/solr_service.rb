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
    connect unless @@connection
    path = params.delete(:path)

    params['extractOnly'] = true
    params['extractFormat'] = 'text'

    # "/solr/techproducts/update/extract"
    conn = Faraday.new(url: 'http://solr:8983/solr/blacklight-core') do |faraday| # TODO @@connection.uri
      faraday.request :multipart #make sure this is set before url_encoded
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
    end

    file = Faraday::UploadIO.new(path, 'application/octet-stream')

    payload = {
      'file' => file,
      'extractOnly' => true,
      'extractFormat' => 'text',
      'wt' => 'json'
    }

    raw_response = conn.post('update/extract', payload).body
    JSON.parse(raw_response) if raw_response.present?
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

    # first page
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
    res = @@connection.get 'select', params: { start: cursor, rows: page_size }
    remaining_records = res["response"]["numFound"].to_i
  end
end
