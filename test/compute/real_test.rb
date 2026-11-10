require "test_helper"

class RealTest < UpCloudTest
  def test_sends_the_token_and_user_agent
    stub = stub_request(:get, "#{API}/zone")
      .with(headers: { "Authorization" => "Bearer ucat_test", "User-Agent" => /\Afog-upcloud\/#{Fog::UpCloud::VERSION} / })
      .to_return(body: JSON.generate(list("zones", "zone", [])))

    compute.regions.all

    assert_requested stub
  end

  def test_sends_a_username_and_password
    stub = stub_request(:get, "#{API}/zone")
      .with(basic_auth: [ "api-user", "1234" ])
      .to_return(body: JSON.generate(list("zones", "zone", [])))

    Fog::Compute.new(provider: "UpCloud", upcloud_username: "api-user", upcloud_password: "1234").regions.all

    assert_requested stub
  end

  def test_requires_a_token_or_a_username_and_password
    error = assert_raises(ArgumentError) { Fog::Compute.new(provider: "UpCloud", upcloud_username: "api-user") }
    assert_match "upcloud_token", error.message
  end

  def test_raises_not_found_with_upclouds_code_and_message
    stub_upcloud :get, "server/missing", status: 404, body: error("SERVER_NOT_FOUND", "The server missing does not exist.")

    error = assert_raises(Fog::UpCloud::Compute::NotFound) { compute.get_server("missing") }
    assert_equal "404 SERVER_NOT_FOUND The server missing does not exist.", error.message
    assert_equal "SERVER_NOT_FOUND", error.code
  end

  def test_raises_error_with_upclouds_message
    stub_upcloud :post, "server", status: 402, body: error("INSUFFICIENT_CREDITS", "There are not enough credits to perform the requested action.")

    error = assert_raises(Fog::UpCloud::Compute::Error) { compute.create_server(zone: "de-fra1") }
    assert_equal "402 INSUFFICIENT_CREDITS There are not enough credits to perform the requested action.", error.message
    assert_nil error.cause
  end

  def test_raises_error_with_a_body_that_isnt_upclouds
    stub_request(:get, "#{API}/zone").to_return(status: 502, body: "Bad Gateway")

    error = assert_raises(Fog::UpCloud::Compute::Error) { compute.list_zones }
    assert_equal "502 Bad Gateway", error.message
    assert_nil error.code
  end

  def test_retries_a_rate_limited_create
    stub = stub_request(:post, "#{API}/server")
      .to_return({ status: 429, body: "" }, { status: 202, body: JSON.generate("server" => fixture(:server)) })

    assert_equal 202, compute.create_server(zone: "de-fra1").status
    assert_requested stub, times: 2
  end

  def test_retries_a_get_that_fails_with_a_server_error
    stub = stub_request(:get, "#{API}/server/#{fixture(:server)["uuid"]}")
      .to_return({ status: 503, body: "" }, { status: 200, body: JSON.generate("server" => fixture(:server)) })

    assert_equal "ci-1", compute.servers.get(fixture(:server)["uuid"]).hostname
    assert_requested stub, times: 2
  end

  def test_does_not_retry_a_create_that_fails_with_a_server_error
    stub = stub_upcloud(:post, "server", status: 500, body: error("INTERNAL_ERROR", "Internal error"))

    assert_raises(Fog::UpCloud::Compute::Error) { compute.create_server(zone: "de-fra1") }
    assert_requested stub, times: 1
  end

  def test_gives_up_after_the_retry_delays
    stub = stub_upcloud(:get, "zone", status: 429, body: error("TOO_MANY_REQUESTS", "Rate limit reached"))

    error = assert_raises(Fog::UpCloud::Compute::Error) { compute.regions.all }
    assert_equal "429 TOO_MANY_REQUESTS Rate limit reached", error.message
    assert_requested stub, times: 4
  end

  def test_retries_a_delete_when_the_connection_drops
    stub = stub_request(:delete, "#{API}/storage/abc").to_raise(Excon::Error::Socket.new(Errno::ECONNRESET.new)).then.to_return(status: 204)

    assert_equal 204, compute.delete_storage("abc").status
    assert_requested stub, times: 2
  end
end
