defmodule World do
  use Actor
	
  # API methods
  ######################
  
  def new(name) do
    state = HashDict.new([name: name, areas: HashDict.new])
    start(state)
  end
  
  attribute :name, :string
  
  def area(world_pid, name), do: sync_call(world_pid, :area, {:get, name})
  def area(world_pid, name, area_pid), do: sync_call(world_pid, :area, {:put, name, area_pid})
  
  def main_area(world_pid), do: sync_call(world_pid, :area, {:get, "Main"})
  def main_area(world_pid, area_pid), do: sync_call(world_pid, :area, {:put, "Main", area_pid})
  
  # Private
  ###############
  
  defp handle(:api, :area, {:get, name}, state, sender) do
    areas = Dict.get(state, :areas)
		area = Dict.get(areas, name)
		sender <- {:area, area}
		state
  end
  
  defp handle(:api, :area, {:put, name, area}, state, sender) do
    areas = Dict.get(state, :areas)
    areas = Dict.put(areas, name, area)
    sender <- {:area, :ok}
    Dict.put(state, :areas, areas)
  end
  
  
  # error
  handle_unknown
  
end


