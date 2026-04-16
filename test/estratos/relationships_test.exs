defmodule Estratos.RelationshipsTest do
  use Estratos.DataCase, async: true

  alias Estratos.Entities
  alias Estratos.Relationships
  alias Estratos.Relationships.Relationship
  alias Estratos.Worlds.World

  @valid_world_attrs %{name: "Test World"}

  defp create_world do
    {:ok, world} =
      %World{}
      |> World.changeset(@valid_world_attrs)
      |> Estratos.Repo.insert()

    world
  end

  defp create_continent(world, name \\ "Aurelia") do
    {:ok, c} = Entities.create_continent(world, %{name: name})
    c
  end

  defp create_country(world, name \\ "Valdoria") do
    {:ok, c} = Entities.create_country(world, %{name: name})
    c
  end

  defp valid_attrs(source, source_type, target, target_type, overrides \\ %{}) do
    Map.merge(
      %{
        source_type: source_type,
        source_id: source.id,
        target_type: target_type,
        target_id: target.id,
        type: "contains"
      },
      overrides
    )
  end

  # ---------------------------------------------------------------------------
  # create_relationship/1
  # ---------------------------------------------------------------------------

  describe "create_relationship/1" do
    test "creates a relationship with valid fields" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)

      attrs = valid_attrs(continent, "continent", country, "country")
      assert {:ok, rel} = Relationships.create_relationship(attrs)

      assert rel.source_type == "continent"
      assert rel.source_id == continent.id
      assert rel.target_type == "country"
      assert rel.target_id == country.id
      assert rel.type == "contains"
      assert rel.attributes == %{}
    end

    test "stores custom attributes" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)

      attrs = valid_attrs(continent, "continent", country, "country", %{attributes: %{"since" => 1400}})
      assert {:ok, rel} = Relationships.create_relationship(attrs)
      assert rel.attributes == %{"since" => 1400}
    end

    test "rejects missing required fields" do
      assert {:error, changeset} = Relationships.create_relationship(%{})
      errors = errors_on(changeset)
      assert Map.has_key?(errors, :source_type)
      assert Map.has_key?(errors, :source_id)
      assert Map.has_key?(errors, :target_type)
      assert Map.has_key?(errors, :target_id)
      assert Map.has_key?(errors, :type)
    end

    test "rejects invalid source_type" do
      world = create_world()
      country = create_country(world)

      attrs = %{source_type: "mountain", source_id: 1, target_type: "country", target_id: country.id, type: "borders"}
      assert {:error, changeset} = Relationships.create_relationship(attrs)
      assert %{source_type: [_]} = errors_on(changeset)
    end

    test "rejects invalid target_type" do
      world = create_world()
      continent = create_continent(world)

      attrs = %{source_type: "continent", source_id: continent.id, target_type: "river", target_id: 1, type: "contains"}
      assert {:error, changeset} = Relationships.create_relationship(attrs)
      assert %{target_type: [_]} = errors_on(changeset)
    end

    test "rejects self-relationships (same type and id)" do
      world = create_world()
      continent = create_continent(world)

      attrs = valid_attrs(continent, "continent", continent, "continent")
      assert {:error, changeset} = Relationships.create_relationship(attrs)
      assert %{target_id: [_]} = errors_on(changeset)
    end

    test "allows same entity type with different ids (e.g. allied countries)" do
      world = create_world()
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")

      attrs = valid_attrs(country_a, "country", country_b, "country", %{type: "allied_with"})
      assert {:ok, rel} = Relationships.create_relationship(attrs)
      assert rel.source_id != rel.target_id
    end
  end

  # ---------------------------------------------------------------------------
  # get_relationship!/1
  # ---------------------------------------------------------------------------

  describe "get_relationship!/1" do
    test "returns the relationship by id" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      assert Relationships.get_relationship!(rel.id).id == rel.id
    end

    test "raises on missing id" do
      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(0) end
    end
  end

  # ---------------------------------------------------------------------------
  # update_relationship/2
  # ---------------------------------------------------------------------------

  describe "update_relationship/2" do
    test "updates the type" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      assert {:ok, updated} = Relationships.update_relationship(rel, %{type: "borders"})
      assert updated.type == "borders"
    end

    test "updates attributes" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      assert {:ok, updated} = Relationships.update_relationship(rel, %{attributes: %{"note" => "disputed"}})
      assert updated.attributes == %{"note" => "disputed"}
    end

    test "does not allow clearing type" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      assert {:error, changeset} = Relationships.update_relationship(rel, %{type: nil})
      assert %{type: [_]} = errors_on(changeset)
    end

    test "does not allow changing source/target (fields are ignored)" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      # Trying to change source_id is silently ignored by update_changeset
      {:ok, updated} = Relationships.update_relationship(rel, %{source_id: 9999, type: "borders"})
      assert updated.source_id == continent.id
    end
  end

  # ---------------------------------------------------------------------------
  # delete_relationship/1
  # ---------------------------------------------------------------------------

  describe "delete_relationship/1" do
    test "deletes the relationship" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      assert {:ok, _} = Relationships.delete_relationship(rel)
      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(rel.id) end
    end

    test "does not delete the linked entities" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      Relationships.delete_relationship(rel)
      assert Entities.get_continent!(continent.id).id == continent.id
      assert Entities.get_country!(country.id).id == country.id
    end
  end

  # ---------------------------------------------------------------------------
  # list_relationships_for_entity/2
  # ---------------------------------------------------------------------------

  describe "list_relationships_for_entity/2" do
    test "returns relationships where entity is source" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      result = Relationships.list_relationships_for_entity("continent", continent.id)
      assert length(result) == 1
      assert hd(result).id == rel.id
    end

    test "returns relationships where entity is target" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      result = Relationships.list_relationships_for_entity("country", country.id)
      assert length(result) == 1
      assert hd(result).id == rel.id
    end

    test "returns relationships from both sides combined" do
      world = create_world()
      continent = create_continent(world)
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")

      {:ok, rel1} = Relationships.create_relationship(valid_attrs(continent, "continent", country_a, "country"))
      {:ok, rel2} = Relationships.create_relationship(valid_attrs(country_a, "country", country_b, "country", %{type: "allied_with"}))

      result = Relationships.list_relationships_for_entity("country", country_a.id)
      ids = Enum.map(result, & &1.id)
      assert rel1.id in ids
      assert rel2.id in ids
      assert length(result) == 2
    end

    test "does not return relationships where entity is uninvolved" do
      world = create_world()
      continent = create_continent(world)
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")

      Relationships.create_relationship(valid_attrs(continent, "continent", country_a, "country"))

      result = Relationships.list_relationships_for_entity("country", country_b.id)
      assert result == []
    end

    test "returns empty list when entity has no relationships" do
      world = create_world()
      continent = create_continent(world)

      assert Relationships.list_relationships_for_entity("continent", continent.id) == []
    end

    test "results are ordered by inserted_at ascending" do
      world = create_world()
      continent = create_continent(world)
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")

      {:ok, rel1} = Relationships.create_relationship(valid_attrs(continent, "continent", country_a, "country"))
      {:ok, rel2} = Relationships.create_relationship(valid_attrs(continent, "continent", country_b, "country"))

      result = Relationships.list_relationships_for_entity("continent", continent.id)
      assert Enum.map(result, & &1.id) == [rel1.id, rel2.id]
    end
  end

  # ---------------------------------------------------------------------------
  # delete_relationships_for_entity/2
  # ---------------------------------------------------------------------------

  describe "delete_relationships_for_entity/2" do
    test "deletes all relationships where entity is source or target" do
      world = create_world()
      continent = create_continent(world)
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")

      {:ok, rel1} = Relationships.create_relationship(valid_attrs(continent, "continent", country_a, "country"))
      {:ok, rel2} = Relationships.create_relationship(valid_attrs(continent, "continent", country_b, "country"))

      Relationships.delete_relationships_for_entity("continent", continent.id)

      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(rel1.id) end
      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(rel2.id) end
    end

    test "does not delete relationships for other entities" do
      world = create_world()
      continent = create_continent(world)
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")

      {:ok, _rel1} = Relationships.create_relationship(valid_attrs(continent, "continent", country_a, "country"))
      {:ok, rel2} = Relationships.create_relationship(valid_attrs(country_a, "country", country_b, "country", %{type: "allied_with"}))

      Relationships.delete_relationships_for_entity("continent", continent.id)

      # rel2 involves only country_a and country_b — should survive
      assert Relationships.get_relationship!(rel2.id).id == rel2.id
    end
  end

  # ---------------------------------------------------------------------------
  # Cascade delete via Entities.delete_*
  # ---------------------------------------------------------------------------

  describe "entity deletion cascades to relationships" do
    test "deleting a continent removes its relationships" do
      world = create_world()
      continent = create_continent(world)
      country = create_country(world)
      {:ok, rel} = Relationships.create_relationship(valid_attrs(continent, "continent", country, "country"))

      Entities.delete_continent(continent)

      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(rel.id) end
    end

    test "deleting a country removes its relationships (both source and target)" do
      world = create_world()
      continent = create_continent(world)
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")

      {:ok, rel1} = Relationships.create_relationship(valid_attrs(continent, "continent", country_a, "country"))
      {:ok, rel2} = Relationships.create_relationship(valid_attrs(country_a, "country", country_b, "country", %{type: "allied_with"}))

      Entities.delete_country(country_a)

      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(rel1.id) end
      assert_raise Ecto.NoResultsError, fn -> Relationships.get_relationship!(rel2.id) end
    end

    test "deleting a country does not remove relationships between unrelated entities" do
      world = create_world()
      continent = create_continent(world)
      country_a = create_country(world, "Valdoria")
      country_b = create_country(world, "Arkon")
      country_c = create_country(world, "Zoria")

      {:ok, _} = Relationships.create_relationship(valid_attrs(continent, "continent", country_a, "country"))
      {:ok, rel_b_c} = Relationships.create_relationship(valid_attrs(country_b, "country", country_c, "country", %{type: "allied_with"}))

      Entities.delete_country(country_a)

      assert Relationships.get_relationship!(rel_b_c.id).id == rel_b_c.id
    end
  end
end
