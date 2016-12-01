defmodule Pictures.Download do
  require HTTPoison
  import SweetXml, only: [sigil_x: 2]

  def get_images(bucket_url) do
    get_keys(bucket_url)
    |> Enum.map(fn key -> Task.Supervisor.async_nolink(TaskSupervisor, fn -> {key, get_image(bucket_url, key)} end) end)
    |> Enum.map(fn task -> Task.yield(task, 5000) end)
  end

  def get_image(bucket_url, key) do
    case HTTPoison.get(bucket_url <> "/" <> key) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> {:ok, img: body}
      {:ok, %HTTPoison.Response{body: _, status_code: status_code}} -> {:error, "download request unsuccessful. status code: #{status_code}"}
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, "failed to download img: #{reason}"}
    end
  end

  def get_keys(bucket_url) do
    with {:ok, bucket_objects} <- get_bucket_objects(bucket_url),
         do: Enum.map(bucket_objects[:contents], fn c -> c[:key] end)
  end

  def get_bucket_objects(bucket_url) do
    case HTTPoison.get(bucket_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> parse_bucket(body)
      {:error, %HTTPoison.Error{reason: reason}} -> {:error, "failed to download S3 bucket: #{reason}"}
    end
  end

  defp parse_bucket(xml) do
      parsed_body = xml |> SweetXml.xpath(~x"//ListBucketResult",
      name: ~x"./Name/text()"s,
      is_truncated: ~x"./IsTruncated/text()"s,
      prefix: ~x"./Prefix/text()"s,
      marker: ~x"./Marker/text()"s,
      max_keys: ~x"./MaxKeys/text()"s,
      next_marker: ~x"./NextMarker/text()"s,
      contents: [
        ~x"./Contents"l,
        key: ~x"./Key/text()"s,
        last_modified: ~x"./LastModified/text()"s,
        e_tag: ~x"./ETag/text()"s,
        size: ~x"./Size/text()"s,
        storage_class: ~x"./StorageClass/text()"s,
        owner: [
          ~x"./Owner"o,
          id: ~x"./ID/text()"s,
          display_name: ~x"./DisplayName/text()"s
        ]
      ],
      common_prefixes: [
        ~x"./CommonPrefixes"l,
        prefix: ~x"./Prefix/text()"s
      ]
    )
    {:ok, parsed_body}
  end
end
