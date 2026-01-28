return function()
  local function err(msg)
    MessageBox({
      title = "Instance Splitter",
      message = msg,
      commands = { { value = 1, name = "OK" } }
    })
  end

  local function toint(v) return tonumber(v) end

  local function validateRange(a, b)
    return a and b and a <= b
  end

  -- Compact syntax builder
  -- Depth 1: Fixture F Thru L
  -- Depth 2: Fixture F Thru L.L2F Thru L2L
  -- Depth 3: Fixture F Thru L.L2F Thru L2L.L3F Thru L3L
  local function buildCompactSelection(fs, fe, block)
    if block.depth == 1 then
      return string.format("Fixture %d Thru %d", fs, fe)

    elseif block.depth == 2 then
      return string.format(
        "Fixture %d Thru %d.%d Thru %d",
        fs, fe, block.l2f, block.l2l
      )

    elseif block.depth == 3 then
      return string.format(
        "Fixture %d Thru %d.%d Thru %d.%d Thru %d",
        fs, fe,
        block.l2f,
        block.l2l,
        block.l3f,
        block.l3l
      )
    end
    return nil
  end

  local function selectionCountSafe()
    if SelectionCount then return SelectionCount() end
    return nil
  end

  -- STEP 1: Main setup
  local setup = MessageBox({
    title = "Instance Splitter",
    message = "Define fixture range and blocks.",
    inputs = {
      { name="Prefix", value="PL" },
      { name="Fixture First", value="901" },
      { name="Fixture Last", value="903" },
      { name="Number of Blocks", value="2" },
    },

    states = {
      { name="Create ALL HEADS group", state=true },
    },

    selectors = {
      {
        name="Store Mode",
        type=1,
        selectedValue=1,
        values={
          ["Overwrite"]=1,
          ["Merge"]=2,
        }
      }
    },

    commands = {
      { name="Next", value=1 },
      { name="Cancel", value=0 },
    }
  })

  if not setup or setup.success ~= true or setup.result ~= 1 then return end

  local prefix  = tostring(setup.inputs["Prefix"] or "")
  local fs      = toint(setup.inputs["Fixture First"])
  local fe      = toint(setup.inputs["Fixture Last"])
  local nBlocks = toint(setup.inputs["Number of Blocks"])

  if prefix == "" then return err("Prefix is required.") end
  if not validateRange(fs, fe) then return err("Fixture range is invalid.") end
  if not nBlocks or nBlocks < 1 or nBlocks > 20 then
    return err("Number of Blocks must be between 1 and 20.")
  end

  local makeHeads = true
  if setup.states and setup.states["Create ALL HEADS group"] ~= nil then
    makeHeads = setup.states["Create ALL HEADS group"] == true
  end

  local storeFlag = "/Overwrite"
  local mode = setup.selectors and setup.selectors["Store Mode"] or 1
  if tonumber(mode) == 2 then storeFlag = "/Merge" end

  -- Optional ALL HEADS
  if makeHeads then
    Cmd("ClearAll")
    Cmd(string.format("Fixture %d Thru %d", fs, fe))
    local c = selectionCountSafe()
    if c and c == 0 then
      err("ALL HEADS selected nothing. Check fixture range.")
    else
      Cmd(string.format(
        'Store Group "%s ALL HEADS" %s /NoConfirmation',
        prefix, storeFlag
      ))
    end
    Cmd("ClearAll")
  end

  -- STEP 2: Block definitions
  local blocks = {}

  for i = 1, nBlocks do
    local blockUi = MessageBox({
      title = string.format("Define Block %d of %d", i, nBlocks),
      message =
        "Depth:\n" ..
        "1 = Fixtures\n" ..
        "2 = Fixture.Sub\n" ..
        "3 = Fixture.Sub.Pixel\n\n" ..
        "Example:\n" ..
        "Fixture 901 Thru 903.1 Thru 2.1 Thru 999",
      inputs = {
        { name="Block Name", value=string.format("BLOCK %d", i) },
        { name="Depth (1/2/3)", value="3" },
        { name="L2 First", value="1" },
        { name="L2 Last", value="2" },
        { name="L3 First", value="1" },
        { name="L3 Last", value="999" },
      },
      commands = {
        { name="Add Block", value=1 },
        { name="Cancel", value=0 },
      }
    })

    if not blockUi or blockUi.result ~= 1 then return end

    local name  = tostring(blockUi.inputs["Block Name"] or "")
    local depth = toint(blockUi.inputs["Depth (1/2/3)"])
    local l2f   = toint(blockUi.inputs["L2 First"])
    local l2l   = toint(blockUi.inputs["L2 Last"])
    local l3f   = toint(blockUi.inputs["L3 First"])
    local l3l   = toint(blockUi.inputs["L3 Last"])

    if name == "" then return err("Block Name is required.") end
    if depth ~= 1 and depth ~= 2 and depth ~= 3 then
      return err("Depth must be 1, 2, or 3.")
    end
    if depth >= 2 and not validateRange(l2f, l2l) then
      return err("L2 range is invalid.")
    end
    if depth == 3 and not validateRange(l3f, l3l) then
      return err("L3 range is invalid.")
    end

    blocks[#blocks+1] = {
      name = name,
      depth = depth,
      l2f = l2f, l2l = l2l,
      l3f = l3f, l3l = l3l,
    }
  end

  -- STEP 3: Build groups
  for _, b in ipairs(blocks) do
    Cmd("ClearAll")
    local selCmd = buildCompactSelection(fs, fe, b)
    Cmd(selCmd)

    local c = selectionCountSafe()
    if c and c == 0 then
      err("Block '" .. b.name .. "' selected nothing.")
    else
      Cmd(string.format(
        'Store Group "%s %s" %s /NoConfirmation',
        prefix, b.name, storeFlag
      ))
    end
    Cmd("ClearAll")
  end

  MessageBox({
    title="Instance Splitter",
    message="Done.",
    commands={{value=1, name="OK"}}
  })
end
