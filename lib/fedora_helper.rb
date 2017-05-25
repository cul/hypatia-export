module FedoraHelper

  def self.config
    Rails.application.config_for(:fedora)
  end


  def self.repo
    conf = self.config
    Rubydora.connect(url: conf['url'], user: conf['user'], password: conf['password'])
  end

  def self.riquery(query)
    self.repo.risearch(query, format: 'json', lang: 'itql')
  end

  def self.make_asset_active(pid, log_message)
    #PUT: /objects/#{pid}?state=A&logMessage=#{log_message}
    c = config
    uri = URI("#{c['url']}/objects/#{pid}?state=A&logMessage=#{log_message}")

    req = Net::HTTP::Put.new(uri)
    req.basic_auth(c['user'], c['password'])

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
    
    unless res.is_a?(Net::HTTPSuccess)
      raise "there was an error while making asset active #{res.inspect}"
    end
    # check returned status
  end
end
