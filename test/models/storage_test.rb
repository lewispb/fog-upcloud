require "test_helper"

class StorageTest < UpCloudTest
  def test_lists_storages_of_a_type_by_label
    stub = stub_upcloud(:get, "storage/normal?label=role%3Dci", body: list("storages", "storage", [ fixture(:storage) ]))

    storage = only(compute.storages.all(type: :normal, label: "role=ci"))

    assert_requested stub
    assert_equal "ci-1", storage.title
    assert_equal "maxiops", storage.tier
    assert storage.private?
  end

  def test_lists_every_storage
    stub_upcloud :get, "storage", body: list("storages", "storage", [ fixture(:storage) ] + fixture(:templates))

    assert_equal 3, compute.storages.all.size
  end

  def test_gets_a_storage
    stub_upcloud :get, "storage/#{fixture(:storage)["uuid"]}", body: { "storage" => fixture(:storage) }

    assert_equal 80, compute.storages.get(fixture(:storage)["uuid"]).size
  end

  def test_templatizes_a_storage_into_an_image
    storage = compute.storages.new(fixture(:storage))
    stub = stub_request(:post, "#{API}/storage/#{storage.id}/templatize")
      .with(body: { "storage" => { "title" => "ci-linux-20261110" } })
      .to_return(status: 201, body: JSON.generate("storage" => fixture(:templates).last.merge("state" => "maintenance", "title" => "ci-linux-20261110")))

    image = storage.templatize(title: "ci-linux-20261110")

    assert_requested stub
    assert_kind_of Fog::UpCloud::Compute::Image, image
    assert_equal "ci-linux-20261110", image.title
    refute image.ready?
  end

  def test_destroys_a_storage
    stub = stub_upcloud(:delete, "storage/#{fixture(:storage)["uuid"]}?backups=delete", status: 204)

    compute.storages.new(fixture(:storage)).destroy

    assert_requested stub
  end
end
