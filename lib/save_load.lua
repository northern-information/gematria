local save_load = {}
save_load.folder_path = norns.state.data .. "gematria_data/" 
local pset_folder_path  = save_load.folder_path .. ".psets/"

function save_load.deep_copy(orig, copies)
  copies = copies or {}
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      if copies[orig] then
          copy = copies[orig]
      else
          copy = {}
          copies[orig] = copy
          for orig_key, orig_value in next, orig, nil do
              copy[save_load.deep_copy(orig_key, copies)] = save_load.deep_copy(orig_value, copies)
          end
          setmetatable(copy, save_load.deep_copy(getmetatable(orig), copies))
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

function save_load.save_gematria_data(name_or_path)
  if name_or_path then
    if os.rename(save_load.folder_path, save_load.folder_path) == nil then
      os.execute("mkdir " .. save_load.folder_path)
      os.execute("mkdir " .. pset_folder_path)
      os.execute("touch" .. pset_folder_path)
    end

    local save_path
    if string.find(name_or_path,"/") == 1 then
      local x,y = string.find(name_or_path,save_load.folder_path)
      local filename = string.sub(name_or_path,y+1,#name_or_path-4)
      local pset_path = pset_folder_path .. filename
      params:write(pset_path)
      print(pset_path)
      save_path = name_or_path
    elseif string.find(name_or_path,"autosave")==nil then -- load pset unless loading from autosave 
      local pset_path = pset_folder_path .. name_or_path
      params:write(pset_path)
      save_path = save_load.folder_path .. name_or_path  ..".gmt"
    else
      params:write(pset_path)
      save_path = save_load.folder_path .. name_or_path  ..".gmt"
    end
    
    -- save gematria_data
    local gematria_data = gematria
     
    local save_object = {}
    save_object = gematria_data
    tab.save(save_object, save_path)
    print("saved gematria data!")
  else
    print("save cancel")
  end
end

function save_load.remove_gematria_data(path)
   if string.find(path, 'gematria') ~= nil then
    local data = tab.load(path)
    if data ~= nil then
      print("data found to remove", path)
      os.execute("rm -rf "..path)

      local start,finish = string.find(path,save_load.folder_path)

      local data_filename = string.sub(path,finish+1)
      local start2,finish2 = string.find(data_filename,".gmt")
      local pset_filename = string.sub(path,finish+1,finish+start2-1)
      local pset_path = pset_folder_path .. pset_filename
      print("pset path found",pset_path)
      os.execute("rm -rf "..pset_path)  
    else
      print("no data found to remove")
    end
  end
end

function save_load.load_gematria_data(path)
  gematria_data = tab.load(path)
  if gematria_data ~= nil then
    print("gematria data found", path)
    local start,finish = string.find(path,save_load.folder_path)

    local data_filename = string.sub(path,finish+1)
    local start2,finish2 = string.find(data_filename,".gmt")
    local pset_filename = string.sub(path,finish+1,finish+start2-1)
    local pset_path = pset_folder_path .. pset_filename
    -- load pset unless loading from autosave 
    if string.find(pset_path,"autosave")==nil then
      print("pset path found",pset_path)
      print("READ",string.find(pset_path,"autosave"))
      params:read(pset_path)
    end

    -- load gematria data
    for i = 0, 3  do
      local output = "o" .. i + 1
      gematria[output].cipher = save_load.deep_copy(gematria_data[output].cipher)
      gematria[output].now = save_load.deep_copy(gematria_data[output].now)
      gematria[output].shape = save_load.deep_copy(gematria_data[output].shape)
      gematria[output].slew:settable(save_load.deep_copy(gematria_data[output].slew.data))
      gematria[output].division = save_load.deep_copy(gematria_data[output].division)
      gematria[output].enabled = save_load.deep_copy(gematria_data[output].enabled)
    end

    
    
    
    
    
    

    

    
    
    
    
    
    

    print("gematria data is now loaded")
          
 else
    print("no data")
  end
end

function save_load.init()

  params:add_separator("DATA MANAGEMENT")
  params:add_group("gematria data",5)

  params:add{
    type="option", id = "autosave", name="autosave" ,options={"off","on"}, default=AUTOSAVE_DEFAULT, 
    action=function() end
  }          
  params:hide("autosave")

  params:add_trigger("save_gematria_data", "> SAVE GEMATRIA DATA")
  params:set_action("save_gematria_data", function(x) textentry.enter(save_load.save_gematria_data) end)

  params:add_trigger("overwrite_gematria_data", "> OVERWRITE GEMATRIA DATA")
  params:set_action("overwrite_gematria_data", function(x) fileselect.enter(save_load.folder_path, save_load.save_gematria_data) end)

  params:add_trigger("remove_gematria_data", "< REMOVE GEMATRIA DATA")
  params:set_action("remove_gematria_data", function(x) fileselect.enter(save_load.folder_path, save_load.remove_gematria_data) end)

  params:add_trigger("load_gematria_data", "> LOAD GEMATRIA DATA" )
  params:set_action("load_gematria_data", function(x) fileselect.enter(save_load.folder_path, save_load.load_gematria_data) end)

  -- params:add_trigger("remove_plant_from_garden", "< REMOVE PLANT FROM GARDEN" )

  -- params:set_action("remove_plant_from_garden", function(x) 
  --   local saved_sequins = tab.load(saved_sequins_path) or {"no plants planted"}
  --   listselect.enter(saved_sequins, save_load.remove_plant_from_garden) 
  -- end)

end

return save_load
