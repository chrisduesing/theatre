defrecord World, geography: HashDict.new
defrecord Room, x: 0, y: 0, description: ""

defmodule WorldBuilder do
	
	def new do
		world = init()
		create(world)
	end

	defp init do
		World.new
	end

	defp create(world) do
		coord_list = Enum.to_list(1 .. 10)
		room_list = lc x inlist coord_list, y inlist coord_list do
			room(x, y, room_description(x, y))
		end
		place(room_list, world)
	end

	defp room_description(x, y) do
		"Room at #{x}, #{y}"
	end

	defp room(x, y, description) do
		Room.new(x: x, y: y, description: description)
	end

	defp place([], world) do
		world
	end

	defp place([room | tail], world) do
		point = {room.x, room.y}
		geography = Dict.put(world.geography, point, room)
		place(tail, world.geography(geography))
	end

end