defmodule Pictures.Server do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def dowload_images(server, img_bucket_url) do
    GenServer.call(server, {:download_images, img_bucket_url})
  end

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:download_images, image_bucket_url}) do
    {:reply, {:ok, Pictures.Download.get_images(image_bucket_url)}}
  end
end
