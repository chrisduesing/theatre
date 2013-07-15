# Founderia

a game

*** TODO: consistency!

Right now there are no ids, but I am passing rooms by location and everything else by pid

Proposed Solution:

All functions take pids, but references between objects store ids (room.avatars == list of avatar_ids)

Each type has a .find(id) method, in order to re-constitute relationships to real objects

Some kind of persistence, though it would be nice to just use ets or something for now, it can go away at restart

World can serve as the lookup point for live processes, translate things like coords to rooms

# Command line usage

iex(1)> founderia = Founderia.founderia  
PID<0.81.0>

iex(2)> world = Founderia.home_world  
PID<0.54.0>

iex(3)> area = World.area(world, "Outside")  
PID<0.55.0>

iex(4)> room = Area.room(area, {1, 1})  
PID<0.62.0>

iex(5)> firedrake = Avatar.new("Firedrake")  
PID<0.82.0>

iex(6)> Avatar.e  
ensure/1         enter_world/4    equipment/1      equipment/2  
iex(6)> Avatar.enter_world(firedrake, world, area, room)  
PID<0.82.0>

iex(7)> Avatar.room firedrake  
PID<0.62.0>

iex(8)> Avatar.move firedrake, :south  
PID<0.82.0>

iex(9)> Avatar.room firedrake  
PID<0.57.0>

iex(10)> room = Avatar.room firedrake  
PID<0.57.0>

iex(11)> Room.description room  
"Room at 0, 1"
