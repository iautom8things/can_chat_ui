defmodule CanChatUI.Scene.Splash do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  @note """
  CanChat
  """

  @text_size 10
  @delay 1250

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    ScenicFontPressStart2p.load()

    viewport = opts[:viewport]
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(viewport)
    center = {0.5 * width, 0.5 * height}

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: @text_size)
      |> text(@note, text_align: :center, translate: center, id: :logo)

    Process.send_after(self(), :connect, @delay)

    {:ok, %{graph: graph, viewport: viewport}, push: graph}
  end

  def handle_info(:connect, %{viewport: vp} = state) do
    ViewPort.set_root(vp, {CanChatUI.Scene.Connect, nil})
    {:noreply, state}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
end
