defmodule World.Builder do
	
	@grid_bottom 0
	@grid_top 4
	
	def build_world do
		world = init()
		create(world)
		world
	end

	defp init do
		World.start
	end

	defp create(world) do
		coord_list = Enum.to_list(@grid_bottom .. @grid_top)
		room_list = lc x inlist coord_list, y inlist coord_list do
			Room.start(x, y, room_description(x, y))
		end
		place(room_list, world)
		generate_height(world)
	end

	defp room_description(x, y) do
		"Room at #{x}, #{y}"
	end

	defp place([], _world) do
		:ok
	end

	defp place([room | tail], world) do
		point = Room.coords(room)
		World.add_room(world, point, room)
		place(tail, world)
	end

	defp generate_height(world) do
		height_from_rand(@grid_bottom, @grid_bottom, world)
	end

	defp height_from_rand(@grid_top, @grid_top, _world) do
		:ok
	end

	defp height_from_rand(x, y, world) do
		room = World.room(world, {x, y})
		potential_rooms = [World.room(world, {x + 1, y}), World.room(world, {x, y + 1}), World.room(world, {x - 1, y}), World.room(world, {x, y - 1})]
		adjacent_rooms = Enum.filter(potential_rooms, fn(room) -> room != nil end)
		rands = Enum.map(adjacent_rooms, fn(room) -> Room.rand(room) end)
		sum = Enum.reduce(rands, 0, fn(x, acc) -> x + acc end)
		average = sum / length(rands)
		Room.update_height(room, average)
		if x + 1 > @grid_top do
			height_from_rand(@grid_bottom, y + 1, world)
		else
			height_from_rand(x + 1, y, world)
		end
	end
	

end