defmodule Estratos.Layers do
  @moduledoc """
  Predefined layer definitions. Layers group entity types for visibility toggling.
  No DB table — definitions live in code. Toggle state is session-only (LiveView assign).
  """

  @layers [
    %{
      slug: "geographic",
      name: "Geographic",
      icon: "hero-globe-americas-micro",
      entity_types: ["continent", "ocean"]
    },
    %{
      slug: "political",
      name: "Political",
      icon: "hero-building-library-micro",
      entity_types: ["country", "city"]
    }
  ]

  @doc "Returns all layer definitions."
  def list_layers, do: @layers

  @doc "Returns a MapSet of all layer slugs (used for initializing active_layers)."
  def all_slugs, do: MapSet.new(@layers, & &1.slug)

  @doc "Returns the slug of the layer that contains the given entity_type, or nil."
  def layer_for_entity_type(entity_type) do
    Enum.find_value(@layers, fn layer ->
      if entity_type in layer.entity_types, do: layer.slug
    end)
  end

  @doc "Returns the flat list of entity_types visible when the given slugs are active."
  def entity_types_for_layers(active_slugs) do
    @layers
    |> Enum.filter(fn layer -> MapSet.member?(active_slugs, layer.slug) end)
    |> Enum.flat_map(fn layer -> layer.entity_types end)
  end
end
