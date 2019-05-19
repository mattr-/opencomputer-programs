--TODO
-- - add repeatability.
-- - add better documentation.
component = require("component")
robot = require("robot")
terminal = require("term")
sides = require("sides")
inv = component.inventory_controller

local state = {
    seed = nil,
}

function getWaypoints()
  local range = component.navigation.getRange()
  return component.navigation.findWaypoints(range)
end

function waypointCount(table)
  return table["n"]
end

function find(table, label)
  local item = nil
  local index = 1
  while index <= waypointCount(table) do
    waypoint = table[index]
    if waypoint.label == label then
      item = waypoint
    end
    index = index + 1
  end

  return item
end

function move(method, number)
  for i = 1, number do
    method()
  end
end

function prepCropSticks(number)
  number = number * 2
  if robot.count(1) > number then
    robot.select(1)
  else
    robot.select(2)
  end
end

function plantNormalSticks()
  prepCropSticks(1)
  inv.equip()
  robot.useDown(sides.bottom)
  inv.equip()
end

function plantCrossSticks()
  robot.useDown(sides.bottom, true)
end

function clear(count, direction)
  if direction then
    direction()
  end

  for i = 1, count do
    robot.forward()
    robot.swingDown(sides.bottom)
    if robot.count(16) > 0 then
      dumpInventoryToTrashCan()
    end
  end
end


function clearExistingCrops()
  robot.swingDown(sides.bottom)
  clear(2)
  clear(2, robot.turnRight)
  clear(8, robot.turnRight)
  clear(2, robot.turnLeft)
  clear(8, robot.turnLeft)
  clear(2, robot.turnRight)
  clear(8, robot.turnRight)
end


function moveToWaypointByName(waypointName)
  local waypoint = find(getWaypoints(), waypointName)
  moveToWaypoint(waypoint)
end

function ensureFacing(side)
  while component.navigation.getFacing() ~= side do
    robot.turnRight()
  end
end


function moveToWaypoint(waypoint)
  current_x = waypoint.position[1]
  current_y = waypoint.position[2]
  current_z = waypoint.position[3]

  -- x and z need to be 0
  -- y needs to be -2 (because we want to be two above the waypoint)
  -- if the waypoint is below us, y will be negative
  -- if the waypoint is above us, y will be negative
  -- if the waypoint is to the right of us, z will be negative
  -- if the waypoint is to the left of us, z will be positive
  -- if the waypoint is behind us, x will be positive
  -- if the waypoint is in front of us, x will be negative

  -- we're going to assume that there's nothing above us to keep us from
  -- moving around freely
  if robot.up() == false then
    print("Cannot move up to move around freely. I'm stuck!")
    os.exit()
  end

  -- if x is positive, move backwards
  if current_x > 0 then
    move(robot.back, math.abs(current_x))
  end

  -- if x is negative, move forwards
  if current_x < 0 then
    move(robot.forward, math.abs(current_x))
  end

  -- if z is negative, we turn right, then move forward
  if current_z > 0 then
    robot.turnLeft()
    move(robot.forward, math.abs(current_z))
    robot.turnRight() --go back to facing the same way
  end

  if current_z < 0 then
    robot.turnRight()
    move(robot.forward, math.abs(current_z))
    robot.turnLeft()
  end

  if current_y < -2 then
    amount = math.abs(current_y) + -2
    move(robot.down, amount)
  end

  robot.down() --because we moved up previously
end


function moveToStartPosition()
  moveToWaypointByName("seed_start")
end

function clearExtraInventory()
  previousSlot = robot.select()
  for slot = 4, 16 do
    if robot.count(slot) > 0 then
      items = inv.getStackInInternalSlot(slot)
      robot.select(slot)
      robot.dropDown(items["size"])
    end
  end

  robot.select(previousSlot)
end

function pullItemFromInventory(amount)

end

function dumpInventoryToTrashCan()
  -- save our current position and current facing
  plantX, plantY, plantZ = component.navigation.getPosition()
  facing = component.navigation.getFacing()

  -- move to the trashcan waypoint
  ensureFacing(sides.west)
  moveToWaypointByName("trash_can")

  -- dump inventory slots 4 through 16
  clearExtraInventory()

  -- get our trash can position and make a fake waypoint
  currentX, currentY, currentZ = component.navigation.getPosition()
  deltaX = plantX - currentX
  deltaY = plantY - currentY
  deltaZ = plantZ - currentZ

  fakeWaypoint = { position = { deltaX, deltaY, deltaZ } }
  moveToWaypoint(fakeWaypoint)
  ensureFacing(facing)
end

function layDownCrossSticks(number, direction)
  if direction then
    direction()
  end

  prepCropSticks(number)
  inv.equip()
  for i = 1, number do
    robot.forward()
    plantCrossSticks()
  end
  inv.equip()
end

function defaultInventory()
  return({ maxSize = 64, size = 0 })
end

function checkWaypoints()

  local wayPoints = getWaypoints()

  startWaypoint = find(wayPoints, "seed_start")
  endWaypoint = find(wayPoints, "seed_end")
  trashWaypoint = find(wayPoints, "trash_can")
  analyzerWaypoint = find(wayPoints, "seed_analyzer")

  if not (startWaypoint and endWaypoint and trashWaypoint and analyzerWaypoint) then
    return nil
  else
    return ({
      startPoint = startWaypoint,
      endPoint = endWaypoint,
      trash = trashWaypoint,
      analyzer = analyzerWaypoint
    })
  end
end

function reset()
  state.seed = inv.getStackInInternalSlot(3)
  robot.select(1)
  -- move to the trashcan waypoint
  ensureFacing(sides.west)
  moveToWaypointByName("trash_can")

  -- dump inventory slots 4 through 16
  clearExtraInventory()
end

function waitForSeed()
  print "Waiting for seed to plant"
  if not state.seed then
    moveToWaypointByName("seed_start")
    -- The start position is the first block that we want to plant on
    -- Move back three blocks and down two one block so we can gather crop sticks,
    move(robot.back, 3)
    move(robot.down, 1)
    robot.select(3)
    inventorySize = inv.getInventorySize(sides.bottom)

    if inventorySize > 0 then
      repeat
        for i = 1, inventorySize do
          itemSlot = inv.getStackInSlot(sides.bottom, i)
          if itemSlot then
            inv.suckFromSlot(sides.bottom, i, itemSlot.maxSize)
          end
        end
        state.seed = inv.getStackInInternalSlot(3)
      until state.seed
    end

  end
  robot.select(1)
  print "Have seed to plant. Continuing"
end

function analyze_seed()
  ensureFacing(sides.west)
  moveToWaypointByName("seed_analyzer")
  robot.select(3)
  robot.dropDown(state.seed.size)
  os.sleep(10) -- wait 10 seconds for the seed to be analyzed
  robot.suckDown()
  robot.select(1)
end

function main()

  terminal.clear()

  print "Starting up..."

  if not checkWaypoints() then
    print "Unable to find waypoints. Cannot continue."
    os.exit()
  else
    print "Waypoints found. Starting route."
  end

  print "Clearing existing inventory."

  reset()
  waitForSeed()

  -- Double check that our seed has been analyzed
  if state.seed and (not state.seed.hasTag) then
    print "Analyzing seed before planting"
    analyze_seed()
  end

  print "Gathering supplies."
  -- Move to the first way point position and wait
  moveToStartPosition()

  -- The start position is the first block that we want to plant on
  -- Move back two blocks and down two one block so we can gather crop sticks,
  move(robot.back, 2)
  move(robot.down, 1)

  supplyChestSize = inv.getInventorySize(sides.bottom)
  if supplyChestSize == nil then
    print "Couldn't find supplies. Cannot continue."
    os.exit()
  end

  -- We need at least two stacks of crop sticks
  -- They go in slots 1 and 2 in our inventory
  local count = 0
  for i = 1, 2 do
    for j = 1, supplyChestSize do
      supplySlot = inv.getStackInSlot(sides.bottom, j)
      if supplySlot then
        robotSlot = inv.getStackInInternalSlot(i) or defaultInventory()
        -- Figure out how much we need. Assumes that we might have some crop
        -- sticks left over
        amountNeeded = robotSlot["maxSize"] - robotSlot["size"]
        if amountNeeded > 0 then
          if supplySlot["size"] < amountNeeded then
            amountNeeded = supplySlot["size"]
          end

          inv.suckFromSlot(sides.bottom, j, amountNeeded)
        end
      end
    end
  end

  -- Reset our position back to the start
  move(robot.up, 1)
  move(robot.forward, 2)

  -- This gets interesting. We have to determine whether or not we clear the
  -- existing crops first
  if robot.detectDown() then
    print "Existing crops detected. Clearing them out first."
    clearExistingCrops()
    dumpInventoryToTrashCan()
    ensureFacing(sides.west)
    moveToStartPosition()
  end

  ---- Do the placing of crop sticks
  print "Setting up crop sticks."
  plantNormalSticks()
  layDownCrossSticks(2)
  layDownCrossSticks(2, robot.turnRight)
  layDownCrossSticks(8, robot.turnRight)
  layDownCrossSticks(2, robot.turnLeft)
  layDownCrossSticks(8, robot.turnLeft)
  layDownCrossSticks(2, robot.turnRight)
  layDownCrossSticks(8, robot.turnRight)

  ---- move back to start and plant the seed
  ensureFacing(sides.west)
  moveToStartPosition()

  robot.select(3)
  inv.equip()
  print "Planting the seed."
  robot.useDown() -- plant the seed

  ensureFacing(sides.west)
  moveToWaypointByName("seed_end")
  -- move back one more so the plant can grow
  robot.back()

  io.write "Waiting 2 minutes for plants to grow"
  for i = 1, 12 do
      os.sleep(10)
      io.write "."
  end
  io.write("\n")


  robot.select(1)
  robot.forward()
  robot.swingDown()

  print "I have the final seed!"
  -- Dump slots three, four, and five
  -- Do the whole thing over again
end
