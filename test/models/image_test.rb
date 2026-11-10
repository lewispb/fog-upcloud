require "test_helper"

class ImageTest < UpCloudTest
  def test_lists_the_accounts_private_templates
    stub_upcloud :get, "storage/template", body: list("storages", "storage", fixture(:templates))

    image = only(compute.images.all)

    assert_equal "012cfe08-ed18-4dce-93c0-c7e39e6276c8", image.id
    assert_equal "ci-linux-20261107", image.title
    assert_equal "de-fra1", image.zone
    assert_equal 80, image.size
    assert image.ready?
    assert_equal({ "image" => "ci-linux" }, image.labels)
    assert_equal "native", image.template_type
    assert_equal Time.utc(2026, 11, 7, 19, 30), image.created
  end

  def test_lists_public_templates
    stub_upcloud :get, "storage/template", body: list("storages", "storage", fixture(:templates))

    image = only(compute.images.all(type: :public))

    assert image.cloud_init?
    assert_nil image.zone
    assert_equal({}, image.labels)
    assert_equal 2, compute.images.all(type: :all).size
  end

  def test_lists_templates_by_label
    stub = stub_upcloud(:get, "storage/template?label=image%3Dci-linux", body: list("storages", "storage", fixture(:templates).last(1)))

    assert_equal [ "ci-linux-20261107" ], compute.images.all(labels: { "image" => "ci-linux" }).map(&:title)
    assert_requested stub
  end

  def test_gets_only_a_template
    stub_upcloud :get, "storage/#{fixture(:storage)["uuid"]}", body: { "storage" => fixture(:storage) }
    stub_upcloud :get, "storage/missing", status: 404, body: error("STORAGE_NOT_FOUND", "The storage does not exist.")

    assert_nil compute.images.get(fixture(:storage)["uuid"])
    assert_nil compute.images.get("missing")
  end

  def test_destroys_a_template_with_its_backups
    image = compute.images.new(fixture(:templates).last)
    stub = stub_upcloud(:delete, "storage/#{image.id}?backups=delete", status: 204)

    assert image.destroy
    assert_requested stub
  end
end
