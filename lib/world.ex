defmodule World do
	use Actor
	
		# API methods
	######################

	def new(name) do
		state = HashDict.new([name: name, areas: HashDict.new])
		start(state)
	end

	attribute :name, :string

	def area(world_pid, name), do: sync_call(world_pid, {:area, name})
	def area(world_pid, name, area_pid), do: sync_call(world_pid, {:area, name, area_pid})


	# Private
	###############

	defp handle({:area, name}, state, sender) do
		areas = Dict.get(state, :areas)
		area = Dict.get(areas, name)
		sender <- {:area, area}
		state
	end

	defp handle({:area, name, area}, state, _sender) do
		areas = Dict.get(state, :areas)
		areas = Dict.put(areas, name, area)
		Dict.put(state, :areas, areas)
	end

	# error
	defp handle(_, state, sender) do
		sender <- { :error, :unknown_command }
		state
	end

end


