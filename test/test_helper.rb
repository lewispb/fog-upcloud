require "json"
require "minitest/autorun"
require "webmock/minitest"

require "fog/upcloud"
require "fog/upcloud/compute"

class UpCloudTest < Minitest::Test
  API = "https://api.upcloud.com/1.3"

  def setup
    Fog.unmock!
  end

  private
    def compute
      @compute ||= Fog::Compute.new(provider: "UpCloud", upcloud_token: "ucat_test", retry_delays: [ 0, 0, 0 ])
    end

    def fixture(name)
      JSON.parse(File.read(File.join(__dir__, "fixtures", "#{name}.json")))
    end

    def stub_upcloud(method, path, status: 200, body: nil)
      stub_request(method, "#{API}/#{path}").to_return(status: status, body: body && JSON.generate(body), headers: { "Content-Type" => "application/json" })
    end

    def list(plural, singular, items)
      { plural => { singular => items } }
    end

    def only(items)
      assert_equal 1, items.size
      items.first
    end

    def error(code, message)
      { "error" => { "error_code" => code, "error_message" => message } }
    end
end
