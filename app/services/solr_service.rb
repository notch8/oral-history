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
end
