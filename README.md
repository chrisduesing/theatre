# Founderia

a game

*** TODO: consistency!

Right now there are no ids, but I am passing rooms by location and everything else by pid

Proposed Solution:

All functions take pids, but references between objects store ids (room.avatars == list of avatar_ids)

Each type has a .find(id) method, in order to re-constitute relationships to real objects

Some kind of persistence, though it would be nice to just use ets or something for now, it can go away at restart

World can serve as the lookup point for live processes, translate things like coords to rooms
