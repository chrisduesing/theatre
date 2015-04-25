defmodule Npc do
  use Actor

  # API
  ######################

  attribute :avatar, :pid

  def new() do
    state = HashDict.new([avatar: nil])
    start(state)
  end

  def play(player, avatar, world, area, room), do: sync_call(player, :play, {avatar, world, area, room})


  # Private
  ###############

  defp handle(:api, :play, {avatar, world, area, room}, state, sender) do
    state = Dict.put(state, :avatar, avatar)
    Avatar.subscribe(avatar, :room_events, self())
    Avatar.enter_world(avatar, world, area, room)
    sender <- {:play, :ok}
    state
  end

  defp handle(:event, :room_events, {:room, [description: description, avatars: avatars]}, state, _sender) do
    IO.puts description
    IO.puts "The room has the following occupants:"
    Enum.each avatars, fn(avatar) -> 
                           if Avatar.id(avatar) != Avatar.id(Dict.get(state, :avatar)) do
                             IO.puts Avatar.name(avatar) 
                           end
                       end
    IO.puts ""
    state
  end

  defp handle(:event, :room_events, {:enter, avatar}, state, _sender) do
    name = Avatar.name(avatar)
    IO.puts "#{name} just entered the room."
    state
  end

  defp handle(:event, :room_events, {:exit, avatar}, state, _sender) do
    name = Avatar.name(avatar)
    IO.puts "#{name} just left the room."
    state
  end

end