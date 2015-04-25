
defmodule Avatar do
  inventory = []
  attributes = HashDict.new
  states = HashDict.new
  skills = []
  
  attributes = HashDict.put(attributes, :location, {1, 2})

  states = HashDict.put(states, :hunger, 0.9)
  
end

defmodule Ai do
  
  def loop(state) do
    avatar = state.avatar
    states = avatar.states
    priority_state = Enum.max states, fn({state, value}) -> value end
    goal = Goal.Store.find(priority_state.key, :lower)
    skill = Enum.find avatar.skills, fn(skill) -> skill.purpose == goal.state end
    skill.execute
  end
end

defmodule Goal do
  defmacro __using__(_opts) do
    quote do
      def state, :do {:somestate, :raise_or_lower}
      def execute(avatar), :do {:error}
      defoverridable [state: 0, execute: 1]
    end
  end
end

defmodule Hunt do
  use Goal
  
  def state, do: {:hunger, :lower}
  def execute(avatar) do 
    target = :animal
    # should probably check memory first, what if they were already fighting and it fled, etc?
    track_skill = Avatar.skill(:locate, target)
    dir = track_skill.execute(avatar, {target})
    Avatar.walk(dir, 1)
    room = Avatar.room avatar
    if Room.contains(target) do
      #attack
      hunt_skill = Avatar.skill(:kill, target)
      hunt_skill.execute(avatar, {target})
    else
      # loop? or put action back on queue and exit?
    end
  end
end

defmodule Skill do
  defmacro __using__(_opts) do
    quote do
      def purpose, do: :whoknows
      def execute(avatar, params), do: Util.Log.debug("I am not implemented")

      defoverridable [purpose: 0, execute: 1]
    end
  end
end

defmodule Scent do
  use Skill
  def purpose, do: :locate
  def execute(avatar, {target}) do
    distance = 1
    found_in_rooms = Area.search_rooms(Avatar.location avatar, distance, target)
    Enum.first(found_in_rooms)
  end
end

defmodule Walk do
  use Skill
  def purpose, do: :movement
  def execute(avatar, {direction, distance}) do
    
  end
end

