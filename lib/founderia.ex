defmodule Founderia do
	use Application.Behaviour
  
	defrecordp :state, [worlds: nil]
  
	# API
	###############
	def start(_type, _args) do
		state = init()
		pid = spawn_link(Founderia, :loop, [state])
		:erlang.register(:founderia, pid)
		{:ok, pid}
	end
  
	def founderia do
		:erlang.whereis(:founderia)
	end
  
	def main_world do
		:erlang.whereis(:main_world)
	end
  
	def test do
		# get the world, area and a room
		world = Founderia.main_world
		area = World.main_area(world)
		room = Area.room(area, {0,0})
		
		# create a couple NPCs
		avatar1 = Avatar.new("Avatar 1")
		avatar2 = Avatar.new("Avatar 2")
    
		# add them to the world
		Avatar.enter_world(avatar1, world, area, room)
		Avatar.enter_world(avatar2, world, area, room)
    
		# create a player's avatar
		firedrake = Avatar.new("Firedrake")
		player = Player.new
    
		# assign the avatar to the player
		# and enter the world
		Player.play(player, firedrake, world, area, room)
    
		# make a npc walk around
		Avatar.move(avatar2, :south)
		Avatar.move(avatar2, :north)
	end
  
	# Private
	################
	defp init do
		Data.Store.start
		main_world = World.Builder.build_world
		:erlang.register(:main_world, main_world)
		state(worlds: [main_world])
	end
	
  
	def loop(state) do
		_start_time = :erlang.now()
		receive do
			message -> 
				IO.puts inspect(message)
				loop(state)
		after 1000 ->
						state = update_npcs(state)
						loop(state)
		end
	end
  
	defp update_npcs(state) do
		# Avatar.Npcs.wander()
		state
	end
  
end
