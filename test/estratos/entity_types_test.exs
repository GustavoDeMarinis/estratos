defmodule Estratos.EntityTypesTest do
  use ExUnit.Case, async: true

  alias Estratos.EntityTypes

  describe "list_types/0" do
    test "returns all 4 entity types" do
      types = EntityTypes.list_types()
      assert length(types) == 4
      slugs = Enum.map(types, & &1.slug)
      assert "continent" in slugs
      assert "ocean" in slugs
      assert "country" in slugs
      assert "city" in slugs
    end

    test "each type has required keys" do
      for t <- EntityTypes.list_types() do
        assert Map.has_key?(t, :slug)
        assert Map.has_key?(t, :name)
        assert Map.has_key?(t, :color)
        assert Map.has_key?(t, :parent_type)
        assert Map.has_key?(t, :parent_fk)
        assert Map.has_key?(t, :layer)
        assert Map.has_key?(t, :schema_module)
        assert Map.has_key?(t, :create_fn)
        assert Map.has_key?(t, :update_fn)
        assert Map.has_key?(t, :delete_fn)
        assert Map.has_key?(t, :get_fn)
      end
    end
  end

  describe "get_type/1" do
    test "returns the definition for a valid slug" do
      assert %{slug: "continent", name: "Continent"} = EntityTypes.get_type("continent")
      assert %{slug: "ocean", name: "Ocean"} = EntityTypes.get_type("ocean")
      assert %{slug: "country", name: "Country"} = EntityTypes.get_type("country")
      assert %{slug: "city", name: "City"} = EntityTypes.get_type("city")
    end

    test "returns nil for unknown slug" do
      assert EntityTypes.get_type("mountain") == nil
      assert EntityTypes.get_type("") == nil
    end
  end

  describe "color/1" do
    test "returns correct Tailwind color class for each type" do
      assert EntityTypes.color("continent") == "text-green-500"
      assert EntityTypes.color("ocean") == "text-blue-500"
      assert EntityTypes.color("country") == "text-amber-500"
      assert EntityTypes.color("city") == "text-rose-400"
    end

    test "returns fallback color for unknown slug" do
      assert EntityTypes.color("unknown") == "text-base-content"
    end
  end

  describe "name/1" do
    test "returns human-readable name for each type" do
      assert EntityTypes.name("continent") == "Continent"
      assert EntityTypes.name("ocean") == "Ocean"
      assert EntityTypes.name("country") == "Country"
      assert EntityTypes.name("city") == "City"
    end
  end

  describe "parent_type/1" do
    test "returns nil for types without a parent" do
      assert EntityTypes.parent_type("continent") == nil
      assert EntityTypes.parent_type("ocean") == nil
    end

    test "returns parent type slug for types with a parent" do
      assert EntityTypes.parent_type("country") == "continent"
      assert EntityTypes.parent_type("city") == "country"
    end

    test "returns nil for unknown slug" do
      assert EntityTypes.parent_type("unknown") == nil
    end
  end

  describe "parent_fk/1" do
    test "returns nil for types without a parent" do
      assert EntityTypes.parent_fk("continent") == nil
      assert EntityTypes.parent_fk("ocean") == nil
    end

    test "returns FK atom for types with a parent" do
      assert EntityTypes.parent_fk("country") == :continent_id
      assert EntityTypes.parent_fk("city") == :country_id
    end

    test "returns nil for unknown slug" do
      assert EntityTypes.parent_fk("unknown") == nil
    end
  end

  describe "schema_module/1" do
    test "returns the correct Ecto schema module for each type" do
      assert EntityTypes.schema_module("continent") == Estratos.Entities.Continent
      assert EntityTypes.schema_module("ocean") == Estratos.Entities.Ocean
      assert EntityTypes.schema_module("country") == Estratos.Entities.Country
      assert EntityTypes.schema_module("city") == Estratos.Entities.City
    end

    test "returns nil for unknown slug" do
      assert EntityTypes.schema_module("unknown") == nil
    end
  end

  describe "types_in_layer/1" do
    test "returns geographic entity type slugs" do
      types = EntityTypes.types_in_layer("geographic")
      assert "continent" in types
      assert "ocean" in types
      refute "country" in types
      refute "city" in types
    end

    test "returns political entity type slugs" do
      types = EntityTypes.types_in_layer("political")
      assert "country" in types
      assert "city" in types
      refute "continent" in types
      refute "ocean" in types
    end

    test "returns empty list for unknown layer" do
      assert EntityTypes.types_in_layer("unknown") == []
    end
  end
end
