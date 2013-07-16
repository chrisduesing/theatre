defmodule World.Builder do
	
	@grid_bottom 0
	@grid_top 4
	
	def build_world do
		world = World.new("The World")
		area = Area.new("Outside")
		create_rooms(area)
		World.main_area(world, area)
		world
	end

	defp create_rooms(area) do
		coord_list = Enum.to_list(@grid_bottom .. @grid_top)
		room_list = lc x inlist coord_list, y inlist coord_list do
			Room.new({x, y}, room_description(x, y))
		end
		place(room_list, area)
		generate_height(area)
	end

	defp room_description(x, y) do
		"Room at #{x}, #{y}"
	end

	defp place([], _area) do
		:ok
	end

	defp place([room | tail], area) do
		coords = Room.coords(room)
		Area.room(area, coords, room)
		place(tail, area)
	end

	defp generate_height(area) do
		height_from_rand(@grid_bottom, @grid_bottom, area)
	end

	defp height_from_rand(@grid_bottom, @grid_top + 1, _area) do
		:ok
	end

	defp height_from_rand(x, y, area) do
		room = Area.room(area, {x, y})
		potential_rooms = [Area.room(area, {x + 1, y}), Area.room(area, {x, y + 1}), Area.room(area, {x - 1, y}), Area.room(area, {x, y - 1})]
		adjacent_rooms = Enum.filter(potential_rooms, fn(room) -> room != nil end)
		rands = Enum.map(adjacent_rooms, fn(room) -> Room.rand(room) end)
		sum = Enum.reduce(rands, 0, fn(x, acc) -> x + acc end)
		average = sum / length(rands)
		Room.height(room, average)
		if x + 1 > @grid_top do
			height_from_rand(@grid_bottom, y + 1, area)
		else
			height_from_rand(x + 1, y, area)
		end
	end
	

end