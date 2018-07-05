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

  def self.delete_by_id(id)
    connect unless @@connection
    @@connection.delete_by_id(id)
  end

  def self.remove_all
    connect unless @@connection
    @@connection.delete_by_query('*:*')
    @@connection.commit
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
end
