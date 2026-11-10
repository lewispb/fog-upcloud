require "fog/core"
require "fog/json"

require "fog/upcloud/version"

module Fog
  module UpCloud
    extend Fog::Provider

    autoload :Compute, "fog/upcloud/compute"

    service :compute, "Compute"
  end
end
