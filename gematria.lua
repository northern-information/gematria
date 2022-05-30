-- see maiden or
-- gematria.lua for
-- instructions...

function README()
print([[

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A
E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G
M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E
A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M A T R I A G E M
= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

## norns                                                 ## crow                   
- key 1:                     exit                       - in  1: clock in, parameters > clock
- key 2:                     gematria.lattice:toggle()  - in  2: unused
- key 3:                     randomize entire matrix    - out 1: organized electricity                     
- enc 1:                     "target"                   - out 2: organized electricity                     
- "clockwise" enc 2:         "wrap"                     - out 3: organized electricity                     
- "counter-clockwise" enc 2: "fall"                     - out 4: organized electricity  
- enc 3:                     "tune"

## maiden
- access everything via table "gematria"
- access lattice api via "gematria.lattice"
- access crow output 1 via "gematria.o1"
- this README uses "o1" as an example but the same commands work for o2, o3, and o4
- each output has an api for use with livecoding via maiden and/or extending the script:
  - gematria.o1.cipher
  - gematria.o1.now
  - gematria.o1.shape
  - gematria.o1.slew
  - gematria.o1.division
  - gematria.o1.enabled

### cipher
- table, eight steps in stringed hexadecimal
- set with "gematria.o1.cipher[1] = A"
- 0 maps to -5v, crow's min
- F maps to 10v, crow's max

### now
- integer, cipher step right now
- set like "gematria.o1.now = 4"

### shape                                     ### slew
- string, default linear                      - floating sequins in seconds, default 1.0
- set like "gematria.o1.shape = rebound"      - set like "gematria.o1.slew = sequins{.1,.2}"
- valid shapes:                               - the sequins are advanced each step
  - linear                                    
  - sine                                      ### divsion
  - logarithmic                               - float, default 1/4
  - exponential                               - the lattice pattern division
  - now                                       - set like "gematria.o1.division = 0.66"
  - wait                                      
  - over                                      
  - under                                     
  - rebound                                   

### enabled
- boolean, default true
- the lattice pattern state
- set like "gematria.o1.enabled = false"
- can also toggle with "gematria.o1.pattern:toggle()"

## troubleshooting
- if crow's tempo isn't working:
  - make sure you have pulses going into input 1
  - jiggle paramters > clock
  - disconnect and reconnect crow

]])
end

-- setup
-- setup
-- setup
-- setup
-- setup

lattice = require("lattice")
sequins = require("sequins")
gematria = {}

function init()
  crow_connected = "ok"
  crow_disconnected = "lost"
  crow_status = crow_disconnected
  redraw_clock_id = clock.run(redraw_clock)
  screen.aa(0)
  screen.font_face(1)
  screen.font_size(8)
  screen.level(15)
  screen.line_width(1)
  matrix_x = 64
  cell_w, cell_h = 8, 11
  target_index, target_x, target_y = 1, 1, 1
  wrap_timer, fallen_timer = 0, 0
  final = reset()
  gematria.lattice = lattice:new()
  for i = 1, 4 do init_output(i) end
  crow_report()
  gematria.lattice:start()
  README()
end

function init_output(i)
  local output = "o" .. i
  gematria[output] = {}
  gematria[output]["id"] = i
  gematria[output]["cipher"] = get_random_cipher()
  gematria[output]["now"] = 1
  gematria[output]["shape"] = "linear"
  gematria[output]["slew"] = sequins{1.0}
  gematria[output]["volts"] = 0
  gematria[output]["division"] = 1/4
  gematria[output]["enabled"] = true
  gematria[output]["pattern"] = gematria.lattice:new_pattern{
    action = function(t)
      if gematria[output]["enabled"] then
        gematria[output]["pattern"]:set_division(gematria[output]["division"])
        gematria[output].now = util.wrap(gematria[output]["now"] + 1, 1, 8)
        crow.output[gematria[output]["id"]].shape = gematria[output]["shape"]
        crow.output[gematria[output]["id"]].slew = gematria[output]["slew"]()
        crow.output[gematria[output]["id"]].volts = util.linlin(0, 15, -5, 10, gematria[output]["cipher"][gematria[output].now])
      end
    end
  }
end

function randomize_all()
  for i = 1, 4 do
    gematria["o" .. i]["cipher"] = get_random_cipher()
  end
end

function get_random_cipher()
  local out = {}
  for i = 1, 8 do
    table.insert(out, math.random(0, 15))
  end
  return out
end

function reset()
  local out = {}
  for i = 1, 8 do
    out[i] = 0
  end
  return out
end

function r()
  norns.script.load(norns.state.script)
end

-- ui
-- ui
-- ui
-- ui
-- ui

function enc(e, d)
  if e == 1 then
    update_target(d)
  elseif e == 2 then
    if d > 0 then
      wrap_cipher()
    else
      fallen_cipher(d)
    end
  elseif e == 3 then
    update_target_value(d)
  end
end

function update_target(d)
  target_index = util.wrap(target_index + d, 1, 32) -- 4 tracks * 8 steps = 32
  target_x, target_y = get_x_and_y()
end

-- wrap the current cipher forward
function wrap_cipher()
  local t_x, t_y = get_x_and_y()
  local output = "o" .. t_y
  local cipher = gematria[output]["cipher"]
  table.insert(cipher, 1, table.remove(cipher, #cipher))
  gematria[output]["cipher"] = cipher
  wrap_timer = 15
end

function fallen_cipher()
  local t_x, t_y = get_x_and_y()
  o1_cache = gematria.o1.cipher[t_x]
  o2_cache = gematria.o2.cipher[t_x]
  o3_cache = gematria.o3.cipher[t_x]
  o4_cache = gematria.o4.cipher[t_x]
  gematria.o1.cipher[t_x] = o4_cache
  gematria.o2.cipher[t_x] = o1_cache
  gematria.o3.cipher[t_x] = o2_cache
  gematria.o4.cipher[t_x] = o3_cache
  fallen_timer = 15
end

function update_target_value(d)
  local t_x, t_y = get_x_and_y()
  gematria["o" .. t_y].cipher[t_x] = util.wrap(gematria["o" .. t_y].cipher[t_x] + d, 0, 15)
end

-- "if i had more time i would have written a shorter algorithm" - tyler etters
function get_x_and_y()
  local x, y = 1, 1
  if target_index <= 8 then
    y = 1
  elseif target_index <= 16 then
    y = 2
  elseif target_index <= 24 then
    y = 3
  elseif target_index <= 32 then
    y = 4
  end
  x = -1 * (((y - 1) * 8) - target_index)
  return x, y
end

function get_index(x, y)
  return x + ((y - 1) * 8)
end

function key(k, z)
  if z == 0 then return end
  if k == 2 then gematria.lattice:toggle() end
  if k == 3 then randomize_all() end
end

-- graphics
-- graphics
-- graphics
-- graphics
-- graphics

function redraw_clock()
  while true do
    clock.sleep(1/15)
    redraw()
  end
end

function redraw()
  screen.clear()
  screen.level(15)
  draw_reticle()
  for i = 0, 3  do
    local output = "o" .. i + 1
    local y = 5 + (i * cell_h)
    screen.move(0, y + 1)
    screen.text(output)
    screen.move(32, y + 1)
    screen.text(gematria[output]["division"])
    draw_table_to_row_at(gematria[output], matrix_x, y + 1)
    draw_step_at(gematria[output]["now"], matrix_x, y + 1)
  end
  screen.move(0, 44)
  screen.move(1, 50)
  screen.text("crow")
  screen.move(32, 50)
  screen.text(crow_status)
  screen.move(1, 57)
  screen.text("lattice")
  screen.move(32, 57)
  screen.text(gematria.lattice.enabled and "on" or "off")
  screen.move(1, 63)
  screen.text("clock")
  screen.move(32, 63)
  screen.text(get_clock_source())
  draw_gematria()
  if wrap_timer > 0 then
    wrap_timer = wrap_timer - 1
    draw_wrap_timer()
  end
  if fallen_timer > 0 then
    fallen_timer = fallen_timer - 1
    draw_fallen_timer()
  end
  screen.update()
end

function draw_wrap_timer()
  screen.level(15)
  screen.rect(64, 54, 60, 1)
  screen.rect(122, 53, 1, 3)
  screen.rect(121, 52, 1, 5)
  screen.fill()
end

function draw_fallen_timer()
  screen.level(15)
  screen.rect(58, 0, 1, 40)
  screen.rect(57, 38, 3, 1)
  screen.rect(56, 37, 5, 1)
  screen.fill()
end

function draw_reticle()
  local adjust_x, adjust_y = -2, -4
  local x = matrix_x + ((target_x - 1) * cell_w)
  local y = (target_y * (cell_h)) - cell_h
  screen.level(15)
  screen.rect(x - 1, y, cell_w + adjust_x, cell_h + adjust_y)
  screen.fill()
end

function draw_table_to_row_at(output, x, y)
  local iteration = 0
  local t_x, t_y = get_x_and_y()
  for k, v in pairs(output["cipher"]) do
    screen.level(15)
    if output.id == t_y and t_x == (iteration + 1) then
      screen.level(0)
    end
    screen.move(x + (iteration * cell_w), y)
    screen.text(int_to_hex(v))
    iteration = iteration + 1
  end
end

function draw_gematria()
  local x, y = matrix_x, 50
  final = reset()
  for i = 1, 4 do 
    for ii = 1, 8 do
      final[ii] = final[ii] + gematria["o" .. i].cipher[ii]
    end
  end
  screen.level(15)
  local iteration = 0
  for k, v in pairs(final) do
    screen.move(x + (iteration * cell_w), y)
    screen.text(int_to_hex(recursive_gematria(v)))
    iteration = iteration + 1
  end
end

function recursive_gematria(input)
  if input > 15 then
    -- explode the input
    explode = {};
    input_string = tostring(input)
    input_string:gsub(".", function(c) table.insert(explode, c) end)
    -- sum the explosion
    local sum = 0
    for k, v in pairs(explode) do
      sum = sum + tonumber(v)
    end
    -- keep going until it is < 15
    return recursive_gematria(sum)
  else
    return input
  end
end

function int_to_hex(i)
  local values = {}
  values[0]  = "0"  values[1]  = "1"
  values[2]  = "2"  values[3]  = "3"
  values[4]  = "4"  values[5]  = "5"
  values[6]  = "6"  values[7]  = "7"
  values[8]  = "8"  values[9]  = "9"
  values[10] = "A"  values[11] = "B"
  values[12] = "C"  values[13] = "D"
  values[14] = "E"  values[15] = "F"
  return values[i]
end

function draw_step_at(i, x, y)
  local step = i - 1
  screen.level(15)
  screen.move(x + (i * cell_w) - 8, y + 2)
  screen.line_rel(4, 0)
  screen.stroke()
end

function get_clock_source()
  local i = params:get("clock_source")
  local source = ""
  if i == 1 then
    source = "int."
  elseif i == 2 then
    source = "midi"
  elseif i == 3 then
    source = "link"
  elseif i == 4 then
    source = "crow"
  end
  return source
end

function cleanup()
  clock.cancel(redraw_clock_id)
  gematria.lattice:destroy()
end

-- crow
-- crow
-- crow
-- crow
-- crow

norns.crow.add = function()
  norns.crow.init()
  crow_report()
end

norns.crow.remove = function()
  crow_report()
end

function crow_report()
  if norns.crow.connected() then
    crow_status = crow_connected
  else
    crow_status = crow_disconnected
  end
end
