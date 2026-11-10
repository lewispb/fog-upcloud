require "test_helper"

class CatalogTest < UpCloudTest
  def test_lists_plans
    stub_upcloud :get, "plan", body: list("plans", "plan", fixture(:plans))

    flavor = compute.flavors.get("2xCPU-4GB")

    assert_equal "2xCPU-4GB", flavor.name
    assert_equal 2, flavor.core_number
    assert_equal 4096, flavor.memory_amount
    assert_equal 80, flavor.storage_size
    assert_equal "maxiops", flavor.storage_tier
    assert_equal 2, compute.flavors.all.find { |plan| plan.gpu_model }.gpu_amount
  end

  def test_lists_zones
    stub_upcloud :get, "zone", body: list("zones", "zone", fixture(:zones))

    assert_equal [ "de-fra1", "fi-hel1" ], compute.regions.all.select(&:public?).map(&:id)
    assert_equal "fi-hel1", compute.regions.get("fi-fake-priv-cloud").parent_zone
    assert_equal "Frankfurt #1", compute.regions.get("de-fra1").description
  end
end
