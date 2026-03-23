defmodule Estratos.MapStorage do
  @doc """
  Persists an uploaded map image to the filesystem.

  Accepts the temp file path (from a LiveView upload entry) and the original
  filename (used only to extract the extension). Copies the file to the upload
  directory with a UUID-based name and returns the public URL path.

  Returns `{:ok, "/uploads/maps/<uuid>.<ext>"}` or `{:error, reason}`.
  """
  def store(tmp_path, original_filename) do
    ext = original_filename |> Path.extname() |> String.downcase()
    filename = "#{Ecto.UUID.generate()}#{ext}"
    dest = Path.join(upload_dir(), filename)

    with :ok <- File.mkdir_p(upload_dir()),
         :ok <- File.cp(tmp_path, dest) do
      {:ok, "/uploads/maps/#{filename}"}
    end
  end

  @doc """
  Deletes a stored map image given its public URL path.
  """
  def delete(image_path) do
    image_path
    |> Path.basename()
    |> then(&Path.join(upload_dir(), &1))
    |> File.rm()
  end

  defp upload_dir do
    Path.join([:code.priv_dir(:estratos), "static", "uploads", "maps"])
  end
end
