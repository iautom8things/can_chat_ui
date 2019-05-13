defmodule CanChatUI.Component.Button do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias ScenicFontPressStart2p

  import Scenic.Primitives, only: [rect: 3, text: 3, update_opts: 2]

  @width 63
  @height 32
  @font_size 8

  # --------------------------------------------------------
  def verify(data), do: {:ok, data}

  # ----------------------------------------------------------------------------
  def init(opts, config) do
    styles = config[:styles]
    width = config[:styles][:width] || @width
    height = config[:styles][:height] || @height
    font_size = config[:font_size] || @font_size
    pressed? = opts[:pressed?] || false
    selected? = opts[:selected?] || false
    text = opts[:text]

    position = {width * 0.5, height * 0.5}

    graph =
      Graph.build(styles: styles)
      |> rect({width, height}, id: :box)
      |> text(text,
        id: :title,
        text_align: :center,
        translate: position,
        font_size: font_size,
        font: ScenicFontPressStart2p.hash()
      )
      |> pressed?(pressed?)
      |> selected?(selected?)

    {:ok,
     %{
       graph: graph,
       viewport: config[:viewport],
       width: width,
       height: height,
       text: text
     }, push: graph}
  end

  def pressed?(graph, true) do
    graph
    # , stroke: {1, :black}))
    |> Graph.modify(:box, &update_opts(&1, fill: :white))
    |> Graph.modify(
      :title,
      &update_opts(&1, fill: :black)
    )
  end

  def pressed?(graph, false) do
    graph
    # , stroke: {1, :white}))
    |> Graph.modify(:box, &update_opts(&1, fill: :black))
    |> Graph.modify(
      :title,
      &update_opts(&1, fill: :white)
    )
  end

  def selected?(graph, true) do
    graph
    |> Graph.modify(:box, &update_opts(&1, stroke: {1, :white}))
  end

  def selected?(graph, false) do
    graph
    |> Graph.modify(:box, &update_opts(&1, stroke: {1, :black}))
  end
end
