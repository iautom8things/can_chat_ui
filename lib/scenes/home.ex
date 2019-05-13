defmodule CanChatUI.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  alias CanChatUI.Component.Button, as: ButtonComponent

  alias PhoenixClient.{Socket, Channel, Message}
  # import Scenic.Components

  @default_status :avail
  @channel_name "server:lobby"
  @delay_step 1000

  @statuses [
    avail: %{
      light_color: :green,
      slack_status: :none,
      slack_dnd: false,
      slack_emoji: :none,
      time: :none
    },
    pomdro: %{
      light_color: :red,
      slack_status: "Pomodoro Session",
      slack_dnd: true,
      slack_emoji: ":tomato:",
      time: {:minute, 25}
    },
    doctor: %{
      light_color: :green,
      slack_status: "Doctor Appt.",
      slack_dnd: false,
      slack_emoji: ":male-doctor::skin-tone-5:",
      time: {:hour, 1}
    },
    meeting: %{
      light_color: :red,
      slack_status: "In meeting",
      slack_dnd: true,
      slack_emoji: ":calendar:",
      time: {:hour, 2}
    },
    lunch: %{
      light_color: :green,
      slack_status: "Eating lunch",
      slack_dnd: false,
      slack_emoji: ":meat_on_bone:",
      time: {:minute, 90}
    },
    errand: %{
      light_color: :green,
      slack_status: "Running an errand",
      slack_dnd: false,
      slack_emoji: ":man-running::skin-tone-5:",
      time: {:minute, 60}
    }
  ]

  @text_size 8

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    Logger.error("initing! #{inspect(self())}")
    ScenicFontPressStart2p.load()

    viewport = opts[:viewport]
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    # {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(viewport)

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: @text_size)
      |> ButtonComponent.add_to_graph([text: Atom.to_string(@default_status), selected?: true],
        id: :status,
        translate: {0, 0},
        font_size: @text_size
      )
      |> ButtonComponent.add_to_graph([text: "set"],
        id: :set_status,
        translate: {64, 0},
        font_size: @text_size
      )
      |> text("Initializing ...",
        id: :connection_status,
        text_align: :center,
        translate: {64, 48},
        font_size: @text_size,
        font: ScenicFontPressStart2p.hash()
      )

    Process.send_after(self(), {:connect_channel, 1}, 1000)

    {:ok,
     %{
       graph: graph,
       viewport: viewport,
       statuses: Keyword.keys(@statuses),
       selected_button: :status,
       channel: nil,
       retrying: false
     }, push: graph}
  end

  def handle_input(
        {:key, {"right", :press, _}},
        _context,
        %{graph: graph, selected_button: :status} = state
      ) do
    ScenicFontPressStart2p.load()
    Logger.debug("moving right")

    graph =
      graph
      |> Graph.modify(:status, fn %{data: {module, data}} = primitive ->
        data = Keyword.put(data, :selected?, false)

        Scenic.Primitive.put(primitive, {module, data}, [])
      end)
      |> Graph.modify(:set_status, fn %{data: {module, data}} = primitive ->
        data = Keyword.put(data, :selected?, true)

        Scenic.Primitive.put(primitive, {module, data}, [])
      end)

    state = %{state | graph: graph, selected_button: :set_status}

    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {"left", :press, _}},
        _context,
        %{graph: graph, selected_button: :set_status} = state
      ) do
    ScenicFontPressStart2p.load()
    Logger.debug("moving left")

    graph =
      graph
      |> Graph.modify(:status, fn %{data: {module, data}} = primitive ->
        data = Keyword.put(data, :selected?, true)

        Scenic.Primitive.put(primitive, {module, data}, [])
      end)
      |> Graph.modify(:set_status, fn %{data: {module, data}} = primitive ->
        data = Keyword.put(data, :selected?, false)

        Scenic.Primitive.put(primitive, {module, data}, [])
      end)

    state = %{state | graph: graph, selected_button: :status}

    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {" ", :press, _}},
        _context,
        %{
          graph: graph,
          selected_button: :set_status
        } = state
      ) do
    Logger.debug("pressing set status")

    graph =
      graph
      |> Graph.modify(:set_status, fn %{data: {module, data}} = primitive ->
        data = Keyword.put(data, :pressed?, true)

        Scenic.Primitive.put(primitive, {module, data}, [])
      end)

    state = %{state | graph: graph}

    Process.send_after(self(), {:set_conn_status, "Sending ..."}, 0)
    Process.send_after(self(), :submit_status, 100)
    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {" ", :release, _}},
        _context,
        %{graph: graph, selected_button: :set_status} = state
      ) do
    Logger.debug("releasing set status")

    graph =
      graph
      |> Graph.modify(:set_status, fn %{data: {module, data}} = primitive ->
        data = Keyword.put(data, :pressed?, false)

        Scenic.Primitive.put(primitive, {module, data}, [])
      end)

    state = %{state | graph: graph}

    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {"up", :release, _}},
        _context,
        %{graph: graph, selected_button: :status} = state
      ) do
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:status, fn %{data: {module, data}} = primitive ->
        data = Keyword.put(data, :pressed?, false)

        Scenic.Primitive.put(primitive, {module, data}, [])
      end)

    state = %{state | graph: graph}

    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {"down", :release, _}},
        _context,
        %{graph: graph, selected_button: :status} = state
      ) do
    ScenicFontPressStart2p.load()

    graph =
      graph
      |> Graph.modify(:status, fn %{data: {mod, data}} = p ->
        data =
          data
          |> Keyword.put(:pressed?, false)

        Scenic.Primitive.put(p, {mod, data}, [])
      end)

    state = %{state | graph: graph}

    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {"up", :press, _}},
        _context,
        %{statuses: statuses, graph: graph, selected_button: :status} = state
      ) do
    Logger.info("go up...")

    statuses = [new_status | _rest] = shift_list(statuses, :right)

    graph =
      graph
      |> Graph.modify(:status, fn %{data: {mod, data}} = p ->
        data =
          data
          |> Keyword.put(:pressed?, true)
          |> Keyword.put(:text, Atom.to_string(new_status))

        Scenic.Primitive.put(p, {mod, data}, [])
      end)

    state = %{state | statuses: statuses, graph: graph}

    {:noreply, state, push: graph}
  end

  def handle_input(
        {:key, {"down", :press, _}},
        _context,
        %{statuses: statuses, graph: graph, selected_button: :status} = state
      ) do
    ScenicFontPressStart2p.load()
    Logger.info("go down...")

    statuses = [new_status | _rest] = shift_list(statuses, :left)

    graph =
      graph
      |> Graph.modify(:status, fn %{data: {mod, data}} = p ->
        data =
          data
          |> Keyword.put(:pressed?, true)
          |> Keyword.put(:text, Atom.to_string(new_status))

        Scenic.Primitive.put(p, {mod, data}, [])
      end)

    state = %{state | statuses: statuses, graph: graph}

    {:noreply, state, push: graph}
  end

  def handle_input(event, _context, state) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, state}
  end

  def handle_info(
        %Message{event: "phx_error", payload: %{reason: {:error, :econnrefused}}},
        %{retrying: false} = state
      ) do
    Process.send_after(self(), {:set_conn_status, "Lost Conn ..."}, 0)
    # Process.send_after(self(), {:connect_channel, 1}, 1000)

    state = %{state | retrying: true}
    {:noreply, state}
  end

  def handle_info(%Message{event: event, payload: payload}, state) do
    Logger.debug("message ... #{inspect(event)} :: #{inspect(payload)}")
    {:noreply, state}
  end

  def handle_info({:connect_channel, attempt}, state) do
    Logger.warn("attempting connect_channel ... #{attempt}")

    state =
      with {:socket_open?, true} <- {:socket_open?, Socket.connected?(Socket)},
           {:connect_channel, {:ok, _, channel}} <-
             {:connect_channel, Channel.join(Socket, @channel_name, %{player_id: 42})} do
        Process.send_after(self(), {:set_conn_status, "Connected"}, 0)

        Logger.warn("connected! #{attempt}")

        %{state | channel: channel, retrying: false}
      else
        {:connect_channel, {:error, {:already_joined, _pid}}} ->
          Logger.warn("already connected ... #{attempt}")
          state

        any ->
          Logger.error("error, continuing ...: #{inspect(any)}")
          Process.send_after(self(), {:connect_channel, attempt + 1}, 1000)
          state
      end

    {:noreply, state}
  end

  def handle_info({:set_conn_status, status}, %{graph: graph} = state) do
    graph =
      graph
      |> Graph.modify(:connection_status, fn p ->
        %{p | data: status}
      end)

    state = %{state | graph: graph}

    {:noreply, state, push: graph}
  end

  def handle_info(
        :submit_status,
        %{
          channel: channel,
          statuses: [status | _rest]
        } = state
      ) do
    state =
      case Channel.push(channel, "set_status", %{status: status}) do
        {:ok, _payload} ->
          Process.send_after(self(), {:set_conn_status, "Sent"}, 0)
          Process.send_after(self(), {:set_conn_status, "Connected"}, 1000)
          state

        {:error, %{"reason" => "unmatched topic"}} ->
          Process.send_after(self(), {:set_conn_status, "Error! Retry"}, 0)
          Channel.leave(channel)
          Process.send_after(self(), {:connect_channel, 1}, 1000)

          %{state | channel: nil}
      end

    {:noreply, state}
  end

  def handle_info(any, state) do
    Logger.warn("unhandled message: #{inspect(any)}")
    {:noreply, state}
  end

  defp shift_list([cur, next | rest], :left), do: [next | rest] ++ [cur]

  defp shift_list(list, :right) do
    {last, rest} = List.pop_at(list, -1)
    [last | rest]
  end
end
