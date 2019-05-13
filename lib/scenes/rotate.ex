defmodule CanChatUI.Scene.Rotate do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  @note """
  Rotate
  """

  @text_size 10
  @delay 100

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

    # Process.send_after(self(), :connect, @delay)
    Process.send_after(self(), :rotate, @delay)

    {:ok, %{graph: graph, viewport: viewport, rotation: 0.0, rotate?: false}, push: graph}
  end

  def handle_info(:rotate, %{rotate?: false} = state) do
    {:noreply, state}
  end

  def handle_info(:rotate, %{graph: graph, rotation: rot, rotate?: true} = state) do
    Logger.debug("rotation is: #{rot}")

    graph =
      graph
      |> Graph.modify(:logo, &text(&1, @note, rotate: rot * :math.pi()))

    Process.send_after(self(), :rotate, @delay)
    state = %{state | graph: graph}
    state = %{state | rotation: rot + 0.1}
    {:noreply, state, push: graph}
  end

  # def handle_info(:connect, %{viewport: vp} = state) do
  #  ViewPort.set_root(vp, {CanChatUI.Scene.Menu, nil})
  #  {:noreply, state}
  # end

  def handle_input({:key, {" ", :press, _}}, _context, %{rotate?: should_rotate} = state) do
    Logger.info("toggling rotation ...")
    state = %{state | rotate?: !should_rotate}

    if not should_rotate do
      Process.send_after(self(), :rotate, @delay)
    end

    {:noreply, state}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end
end
