defmodule Estratos.EntityTypes do
  @moduledoc """
  Registry of all entity types in the system. Single source of truth for type slug,
  display name, pin color, parent relationship, layer membership, and the Entities
  functions used to create, read, update, delete, and list each type.

  Adding a new entity type requires only a new entry in @types — no other module
  needs to be updated for the dispatch logic.
  """

  alias Estratos.Entities.{Continent, Ocean, Country, City}

  @types [
    %{
      slug: "continent",
      name: "Continent",
      color: "text-green-500",
      parent_type: nil,
      parent_fk: nil,
      layer: "geographic",
      schema_module: Continent,
      list_fn: :list_continents_for_world,
      get_fn: :get_continent!,
      create_fn: :create_continent,
      update_fn: :update_continent,
      delete_fn: :delete_continent
    },
    %{
      slug: "ocean",
      name: "Ocean",
      color: "text-blue-500",
      parent_type: nil,
      parent_fk: nil,
      layer: "geographic",
      schema_module: Ocean,
      list_fn: nil,
      get_fn: :get_ocean!,
      create_fn: :create_ocean,
      update_fn: :update_ocean,
      delete_fn: :delete_ocean
    },
    %{
      slug: "country",
      name: "Country",
      color: "text-amber-500",
      parent_type: "continent",
      parent_fk: :continent_id,
      layer: "political",
      schema_module: Country,
      list_fn: :list_countries_for_world,
      get_fn: :get_country!,
      create_fn: :create_country,
      update_fn: :update_country,
      delete_fn: :delete_country
    },
    %{
      slug: "city",
      name: "City",
      color: "text-rose-400",
      parent_type: "country",
      parent_fk: :country_id,
      layer: "political",
      schema_module: City,
      list_fn: :list_cities_for_world,
      get_fn: :get_city!,
      create_fn: :create_city,
      update_fn: :update_city,
      delete_fn: :delete_city
    }
  ]

  @doc "Returns all registered entity type definitions."
  def list_types, do: @types

  @doc "Returns the definition for a given slug, or nil if not found."
  def get_type(slug), do: Enum.find(@types, &(&1.slug == slug))

  @doc "Returns the Tailwind pin color class for a slug."
  def color(slug) do
    case get_type(slug) do
      nil -> "text-base-content"
      t -> t.color
    end
  end

  @doc "Returns the human-readable name for a slug."
  def name(slug) do
    case get_type(slug) do
      nil -> slug
      t -> t.name
    end
  end

  @doc "Returns the parent entity type slug, or nil if none."
  def parent_type(slug) do
    case get_type(slug) do
      nil -> nil
      t -> t.parent_type
    end
  end

  @doc "Returns the parent FK field atom (e.g. :continent_id), or nil if no parent."
  def parent_fk(slug) do
    case get_type(slug) do
      nil -> nil
      t -> t.parent_fk
    end
  end

  @doc "Returns the Ecto schema module for a slug, or nil if not found."
  def schema_module(slug) do
    case get_type(slug) do
      nil -> nil
      t -> t.schema_module
    end
  end

  @doc "Returns all type slugs belonging to a given layer slug."
  def types_in_layer(layer_slug) do
    @types
    |> Enum.filter(&(&1.layer == layer_slug))
    |> Enum.map(& &1.slug)
  end
end
