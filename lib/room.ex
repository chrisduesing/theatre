defmodule Room do
  use Actor

  # API 
  ######################  

  def new(coords, description) when is_tuple(coords) do
    state = HashDict.new([coords: coords, rand: :random.uniform(), description: description, avatars: []])
    start(state)
  end

  def init(state) do
    :random.seed(:erlang.now())
    state
  end

  attribute :coords, :tuple
  attribute :height, :number
  attribute :description, :string
  attribute :rand, :number
  attribute :avatars, :list

  def exit(room_pid, avatar_pid, to_coords), do: sync_call(room_pid, :exit, {avatar_pid, to_coords})
  def enter(room_pid, avatar_pid, from_coords), do: sync_call(room_pid, :enter, {avatar_pid, from_coords})


  # Private
  ###############

  defp handle(:api, :exit, {avatar, _to_coords}, state, sender) do
    avatars = Dict.get(state, :avatars)
    avatars = List.delete(avatars, avatar) 
    sender <- {:exit, true}
    broadcast(:room_events, {:exit, avatar}, state)
    Dict.put(state, :avatars, avatars)
  end

  defp handle(:api, :enter, {avatar, _from_coords}, state, sender) do
    avatars = Dict.get(state, :avatars)
    avatars = [avatar | avatars]
    sender <- {:enter, true}
    broadcast(:room_events, {:enter, avatar}, state)
    description = Dict.get(state, :description)
    Avatar.notify(avatar, :room_events, {:room, [description: description, avatars: avatars]})
    Dict.put(state, :avatars, avatars)
  end
  
  # error
  handle_unknown
  

end