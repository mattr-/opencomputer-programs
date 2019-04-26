local component = require("component")
local sides = require("sides")

local navigation = {}

local waypoints = nil

function navigation.waypoints()
  if not waypoints then
    local range = component.navigation.getRange()
    waypoints = component.navigation.findWaypoints(range)
  end
  return waypoints
end

function navigation.count()
  return waypoints()["n"]
end

function navigation.find(name)
  local item = nil
  local index = 1

  local count = count()
  while index <= count do
    waypoint = waypoints()[index]
    if waypoint.label == name then
      item = waypoint
      return item
    end
    index = index + 1
  end
  return item
end

function navigation.face(side)
  while component.navigation.getFacing() ~= side do
    robot.turnRight()
  end
end

function navigation.move(method, number)
  checkArg(2, number, "nil", "number")
  for i = 1, number do
    method()
  end
end

function navigation.moveToPointByName(name)
  local waypoint = find(waypoints(), waypointName)
  moveToWaypoint(waypoint)
end

function navigation.moveToWaypoint(waypoint)
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

function navigation.currentPosition()
  return component.navigation.getPosition()
end

function navigation.facing()
  return component.navigation.getFacing()
end

return navigation;
