defmodule Ai do
  use Actor

  # API
  ######################

  attribute :avatar, :pid

  def new(avatar) do
    state = HashDict.new([avatar: avatar])
    start(state)
  end

  def loop(state) do
    avatar = Dict.get(state, :avatar)
    states = Avatar.states avatar
    {state, value} = Enum.max states, fn({state, value}) -> value end
    goal = Goal.Store.find(state, :lower)
    purpose = Goal.purpose goal
    avatar_skills = Avatar.skills avatar, purpose
    Skill.execute skill, avatar
    receive do
      Msg -> Util.Log.debug("Ai received message ~p~n", [Msg])
      loop(state)
    after 1000 ->
            loop(state)
    end
  end

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