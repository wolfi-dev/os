require 'net/http'
require 'uri'
require 'openssl'

def validate_https_connection(url)
  uri = URI.parse(url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.open_timeout = 5
  http.read_timeout = 5

  begin
    response = http.start do |h|
      h.head(uri.path.empty? ? '/' : uri.path)
    end

    puts "✓ Connection successful"
    puts "  SSL Certificate: Valid"
    puts "  Response code: #{response.code}"
    true
  rescue OpenSSL::SSL::SSLError => e
    puts "✗ SSL Error: #{e.message}"
    false
  rescue => e
    puts "✗ Connection failed: #{e.message}"
    false
  end
end

success = validate_https_connection('https://www.example.com') 
exit(success ? 0 : 1)
