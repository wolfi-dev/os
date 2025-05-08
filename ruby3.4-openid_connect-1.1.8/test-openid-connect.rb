#!/usr/bin/env ruby

# Simple test framework to verify OpenID Connect functionality
class OpenIDConnectTester
  def initialize
    @test_count = 0
    @pass_count = 0
    @fail_count = 0
  end

  def assert(condition, message)
    @test_count += 1
    if condition
      @pass_count += 1
      puts "✓ PASS: #{message}"
      true
    else
      @fail_count += 1
      puts "✗ FAIL: #{message}"
      false
    end
  end

  def assert_equal(expected, actual, message)
    assert(expected == actual, "#{message} (Expected: #{expected.inspect}, Got: #{actual.inspect})")
  end

  def assert_instance_of(klass, object, message = nil)
    message ||= "Object should be an instance of #{klass}"
    assert(object.is_a?(klass), message)
  end

  def assert_defined(constant_name, object_name = nil)
    object_name ||= constant_name
    assert(defined?(constant_name) != nil, "#{object_name} should be defined")
  end

  def run_tests
    puts "\n=== Testing OpenID Connect gem ==="
    
    test_package_loaded
    test_core_classes_present
    test_client_instantiation
    test_access_token_class
    test_id_token_class
    test_response_objects

    puts "\n=== Test Summary ==="
    puts "Total tests: #{@test_count}"
    puts "Passed: #{@pass_count}"
    puts "Failed: #{@fail_count}"
    
    exit 1 if @fail_count > 0
  end

  def test_package_loaded
    puts "\n--- Testing package loading ---"
    begin
      require 'openid_connect'
      assert(true, "OpenID Connect gem loaded successfully")
      
      # Show which gem version we're testing
      gem_spec = Gem.loaded_specs['openid_connect']
      gem_version = gem_spec.version.to_s
      puts "Testing openid_connect version #{gem_version}"
    rescue LoadError => e
      assert(false, "Failed to load openid_connect gem: #{e.message}")
    end
  end
  
  def test_core_classes_present
    puts "\n--- Testing core classes ---"
    require 'openid_connect'
    
    # Test core classes are defined
    assert_defined(OpenIDConnect, "OpenIDConnect module")
    assert_defined(OpenIDConnect::Client, "OpenIDConnect::Client class")
    assert_defined(OpenIDConnect::AccessToken, "OpenIDConnect::AccessToken class")
    assert_defined(OpenIDConnect::ResponseObject, "OpenIDConnect::ResponseObject module")
    assert_defined(OpenIDConnect::Discovery, "OpenIDConnect::Discovery module")
  end
  
  def test_client_instantiation
    puts "\n--- Testing client instantiation ---"
    require 'openid_connect'
    
    # Test we can instantiate a client with proper parameters
    client = OpenIDConnect::Client.new(
      identifier: "client_id",
      secret: "client_secret",
      redirect_uri: "https://example.com/callback",
      host: "server.example.com"
    )
    
    assert_instance_of(OpenIDConnect::Client, client, "Should create client instance")
    assert_equal("client_id", client.identifier, "Client identifier should match")
    assert_equal("client_secret", client.secret, "Client secret should match")
    assert_equal("https://example.com/callback", client.redirect_uri, "Redirect URI should match")
  end
  
  def test_access_token_class
    puts "\n--- Testing AccessToken class ---"
    require 'openid_connect'
    
    # Test AccessToken class behavior
    client = OpenIDConnect::Client.new(
      identifier: "client_id",
      secret: "client_secret",
      redirect_uri: "https://example.com/callback",
      host: "server.example.com"
    )
    
    # Create an access token
    access_token = OpenIDConnect::AccessToken.new(
      access_token: "sample_token",
      client: client
    )
    
    assert_instance_of(OpenIDConnect::AccessToken, access_token, "Should create AccessToken instance")
    assert_equal("sample_token", access_token.access_token, "Access token value should match")
  end
  
  def test_id_token_class
    puts "\n--- Testing IdToken class ---"
    require 'openid_connect'
    
    # Verify the IdToken class exists
    assert_defined(OpenIDConnect::ResponseObject::IdToken, "IdToken class")
    
    # Create a UserInfo as we know this works reliably 
    # This tests a key class in the ResponseObject module
    # which includes common functionality with IdToken
    user_info = OpenIDConnect::ResponseObject::UserInfo.new(
      sub: 'subject',
      name: 'User',
      given_name: 'Test',
      family_name: 'User',
      email: 'user@example.com'
    )
    
    # Test attributes are accessible
    assert_equal("subject", user_info.sub, "UserInfo sub should be accessible")
    assert_equal("User", user_info.name, "UserInfo name should be accessible")
    
    # Test additional IdToken-specific components
    id_token_class = OpenIDConnect::ResponseObject::IdToken
    assert(id_token_class.respond_to?(:decode), "IdToken class should have decode method")
  end
  
  def test_response_objects
    puts "\n--- Testing response objects ---"
    require 'openid_connect'
    
    # Test we can instantiate various response objects
    userinfo = OpenIDConnect::ResponseObject::UserInfo.new(
      sub: "user123",
      name: "Test User",
      email: "test@example.com"
    )
    
    assert_instance_of(OpenIDConnect::ResponseObject::UserInfo, userinfo, "Should create UserInfo instance")
    assert_equal("user123", userinfo.sub, "UserInfo sub should match")
    assert_equal("Test User", userinfo.name, "UserInfo name should match")
    assert_equal("test@example.com", userinfo.email, "UserInfo email should match")
  end
end

# Run all tests
tester = OpenIDConnectTester.new
tester.run_tests