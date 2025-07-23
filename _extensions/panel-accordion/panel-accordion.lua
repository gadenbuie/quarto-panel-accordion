-- panel-accordion.lua
-- Transform panel-accordion divs into Bootstrap accordions
-- License: MIT
-- Author: Garrick Aden-Buie (2025) | https://garrickadenbuie.com

local os = require("os")
local accordion_idx = 1

function parse_accordion_contents(div)
  local heading = div.content:find_if(function(el) return el.t == "Header" end)
  if heading ~= nil then
    -- note the level, then build accordion buckets for content after these levels
    local level = heading.level
    local panels = pandoc.List()
    local panel = nil
    for i=1,#div.content do
      local el = div.content[i]

      if el.t == "Header" then
        assert(el.level >= level, "Accordion panel headings must be nested in order: accordions panels should use level " .. level .. " headings, but '" .. pandoc.utils.stringify(el.content) .. "' was found at level " .. el.level .. ".")
      else
        assert(panel, "Accordion panel content must be preceded by a heading. Found '" .. pandoc.utils.stringify(el) .. "' without a preceding header.")
      end

      if el.t == "Header" and el.level == level then
        panel = {
          title = el.content,
          content = pandoc.List(),
          open = el.attr.classes:includes("open"),
          icon = el.attr.attributes["icon"] or "",
        }
        panels:insert(panel)
      else
        panel.content:insert(el)
      end

    end
    return panels, level, div.identifier
  else
    return nil
  end
end

function render_icon(icon_attr)
  if not icon_attr or icon_attr == "" then
    return ""
  end

  if icon_attr:sub(1, 1) == "<" then
    -- HTML detected, return as-is with a space
    return icon_attr .. " "
  else
    -- Bootstrap icon name, wrap in bi classes
    return '<i class="bi bi-' .. icon_attr .. '"></i> '
  end
end

function render_accordion(attr, panels, level, id)
  -- create a unique id for the accordion
  local accordion_id = id
  if accordion_id == nil or accordion_id == "" then
    accordion_id = "accordion-" .. accordion_idx
  end
  accordion_idx = accordion_idx + 1

  -- check if multiple panels can be open
  local multiple = attr.attributes["multiple"] == "true"

  -- determine which panel should be open initially
  local has_open = panels:find_if(function(panel) return panel.open end)
  local first_open_index = nil
  if has_open then
    for i, panel in ipairs(panels) do
      if panel.open then
        first_open_index = i
        if not multiple then
          break -- only first one if not multiple
        end
      end
    end
  end

  -- create accordion container
  local accordion_content = pandoc.List()

  -- add opening accordion div
  accordion_content:insert(pandoc.RawBlock('html', '<div class="accordion" id="' .. accordion_id .. '">'))

  -- create each accordion item
  for i, panel in ipairs(panels) do
    -- quarto.log.output('=== Panel ' .. i .. ' ===')
    -- quarto.log.output(panel)
    local itemid = accordion_id .. "-item-" .. i
    local collapse_id = accordion_id .. "-collapse-" .. i
    local header_id = accordion_id .. "-header-" .. i

    -- determine if this panel should be open
    local is_open = false
    if multiple then
      is_open = panel.open
    else
      is_open = first_open_index == i
    end

    -- accordion item container
    accordion_content:insert(pandoc.RawBlock('html', '  <div class="accordion-item">'))

    -- accordion header
    local h_tag = 'h' .. level
    accordion_content:insert(pandoc.RawBlock('html', '    <' .. h_tag ..  ' class="accordion-header no-anchor m-0 p-0" id="' .. header_id .. '">'))

    -- accordion button
    local button_class = "accordion-button"
    local expanded = "true"
    if not is_open then
      button_class = button_class .. " collapsed"
      expanded = "false"
    end

    accordion_content:insert(pandoc.RawBlock('html',
      '      <button class="' .. button_class .. ' gap-2" type="button" data-bs-toggle="collapse" ' ..
      'data-bs-target="#' .. collapse_id .. '" aria-expanded="' .. expanded .. '" ' ..
      'aria-controls="' .. collapse_id .. '">'))

    -- add title content
    local title_html = pandoc.write(pandoc.Pandoc(pandoc.Plain(panel.title)), 'html')
    -- remove wrapping <p> tags if present
    title_html = title_html:gsub("^<p>", ""):gsub("</p>$", ""):gsub("^%s*", ""):gsub("%s*$", "")
    local icon_html = render_icon(panel.icon)
    title_html = '<div>' .. title_html .. '</div>'
    accordion_content:insert(pandoc.RawBlock('html', '        ' .. icon_html .. title_html))

    accordion_content:insert(pandoc.RawBlock('html', '      </button>'))
    accordion_content:insert(pandoc.RawBlock('html', '    </' .. h_tag .. '>'))

    -- accordion collapse div
    local collapse_class = "accordion-collapse collapse"
    if is_open then
      collapse_class = collapse_class .. " show"
    end

    local parent_attr = ""
    if not multiple then
      parent_attr = ' data-bs-parent="#' .. accordion_id .. '"'
    end

    accordion_content:insert(pandoc.RawBlock('html',
      '    <div id="' .. collapse_id .. '" class="' .. collapse_class .. '"' .. parent_attr ..
      ' aria-labelledby="' .. header_id .. '">'))

    -- accordion body
    accordion_content:insert(pandoc.RawBlock('html', '      <div class="accordion-body">'))

    -- add panel content
    for _, content_el in ipairs(panel.content) do
      accordion_content:insert(content_el)
    end

    accordion_content:insert(pandoc.RawBlock('html', '      </div>'))
    accordion_content:insert(pandoc.RawBlock('html', '    </div>'))
    accordion_content:insert(pandoc.RawBlock('html', '  </div>'))
  end

  -- close accordion container
  accordion_content:insert(pandoc.RawBlock('html', '</div>'))

  return accordion_content
end

function has_bootstrap()
  if not quarto.format.is_html_output() then
    return false
  end

  local paramsJson = quarto.base64.decode(os.getenv("QUARTO_FILTER_PARAMS") or "")
  local quartoParams = quarto.json.decode(paramsJson)

  local value = quartoParams["has-bootstrap"]
  if value == nil then
    return false
  end

  return value
end

function Div(div)
  if not has_bootstrap() then
    return div -- only process for HTML output
  end

  if div.attr.classes:includes("panel-accordion") then
    local panels, level, id = parse_accordion_contents(div)
    if panels and #panels > 0 then
      local accordion_blocks = render_accordion(div.attr, panels, level, id)
      return accordion_blocks
    else
      -- return original div if no panels found
      return div
    end
  end
end

return {
  { Div = Div }
}
