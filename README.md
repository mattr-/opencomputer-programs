# Agricraft seed breeder for OpenComputers

This is a seed breeder for Agricraft crops, driven with an OpenComputers
robot.

## Requirements

The farming area needs to run east to west and should be set up in the following pattern.
```
   a
XXX XXX
X X X X
X X X X
c X X X
c X X X
  X X X
  X X X
  XXX X
   t
```

Here is the legend for the above diagram: 
  - `a` is a normal Agricraft seed analyzer
  - `c` is an inventory of some sort (chests, ender chests, etc.) that
    the robot can pull crop sticks and seeds from.
  - `t` is an extra utilities trash can
  - `X` is a tilled dirt block (aka farmland)

There should be waypoints below the analyzer and trash can that point up
into those blocks. There should also be waypoints that point into the
first dirt block and the last dirt block. They should be named:
 - `seed_analyzer`
 - `trash_can`
 - `seed_start`
 - `seed_end`

The chest closest to the starting point should contain crop sticks. The
chest behind that one should contain seeds to plant. Seeds will be
analyzed first if necessary.


