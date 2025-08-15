-- panel-accordion.lua
-- Transform panel-accordion divs into Bootstrap accordions
-- License: MIT
-- Author: Garrick Aden-Buie (2025) | https://garrickadenbuie.com

--[[
## Bootstrap Accordions

<https://getbootstrap.com/docs/5.3/components/accordion/>

```html
<div class="accordion" id="accordionExample">
  <div class="accordion-item">
    <hX class="accordion-header">
      <button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
        <!-- icon -->
        <div>Accordion Item #1</div>
      </button>
    </hX>
    <div id="collapseOne" class="accordion-collapse collapse show" data-bs-parent="#accordionExample">
      <div class="accordion-body">
        <!-- First accordion item content, shown by default because of .show -->
      </div>
    </div>
  </div>
  <div class="accordion-item">
    <h2 class="accordion-header">
      <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
        <!-- icon -->
        <div>Accordion Item #2</div>
      </button>
    </h2>
    <div id="collapseTwo" class="accordion-collapse collapse" data-bs-parent="#accordionExample">
      <div class="accordion-body">
        <!-- Second accordion item content, hidden by default -->
      </div>
    </div>
  </div>
</div>
```

> Omit the `data-bs-parent` attribute on each `.accordion-collapse` to make
> accordion items stay open when another item is opened.
]]

quarto.doc.add_html_dependency({
  name = "panel-accordion",
  version = "0.0.1",
  scripts = {"panel-accordion.js"}
})

local os = require("os")
local accordion_idx = 1

function parse_accordion_contents(div)
  local heading = div.content:find_if(function(el) return el.t == "Header" end)
  if heading == nil then
    -- no headings found, no accordion to create
    return nil
  end

  -- note the level, then build accordion buckets for content after these levels
  local level = heading.level
  local panels = pandoc.List()
  local panel = nil
  for i = 1, #div.content do
    local el = div.content[i]

    if el.t == "Header" then
      assert(el.level >= level,
        "Accordion panel headings must be nested in order: accordions panels should use level " ..
        level .. " headings, but '" .. pandoc.utils.stringify(el.content) .. "' was found at level " .. el.level .. ".")
    end

    if el.t == "Header" and el.level == level then
      panel = {
        title = el.content,
        content = pandoc.List(),
        open = el.attr.classes:includes("open"),
        icon = el.attr.attributes["icon"] or "",
        id = el.attr.identifier or nil,
        no_anchor = el.attr.classes:includes("no-anchor")
      }
      panels:insert(panel)
    else
      assert(panel,
        "Accordion panel content must be preceded by a heading. Found '" ..
        pandoc.utils.stringify(el) .. "' without a preceding header.")
      panel.content:insert(el)
    end
  end

  return panels, level, div.identifier
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
  accordion_content:insert(pandoc.RawBlock('html',
    string.format('<div class="accordion" id="%s">', accordion_id)
  ))

  -- create each accordion item
  for i, panel in ipairs(panels) do
    local collapse_id = accordion_id .. "-collapse-" .. i
    local header_id = panel.id or accordion_id .. "-header-" .. i

    -- determine if this panel should be open
    local is_open = false
    if multiple then
      is_open = panel.open
    else
      is_open = first_open_index == i
    end

    -- accordion-item
    accordion_content:insert(pandoc.RawBlock('html', '  <div class="accordion-item">'))

    -- accordion-header
    local h_tag = 'h' .. level
    local h_classes = "accordion-header m-0 p-0"
    if panel.no_anchor then
      h_classes = h_classes .. " no-anchor"
    end
    accordion_content:insert(pandoc.RawBlock('html',
      '    <' .. h_tag .. ' class="' .. h_classes .. '" id="' .. header_id .. '">'))

    -- accordion-button
    local button_class = "accordion-button"
    local expanded = "true"
    if not is_open then
      button_class = button_class .. " collapsed"
      expanded = "false"
    end

    accordion_content:insert(pandoc.RawBlock(
      'html',
      string.format(
        '      <button class="%s gap-2" type="button" data-bs-toggle="collapse" data-bs-target="#%s" aria-expanded="%s" aria-controls="%s">',
        button_class, collapse_id, expanded, collapse_id
      )
    ))

    -- add title content
    accordion_content:insert(render_title(panel.title, panel.icon))

    -- /accordion-button
    accordion_content:insert(pandoc.RawBlock('html', '      </button>'))
    -- /accordion-header
    accordion_content:insert(pandoc.RawBlock('html', '    </' .. h_tag .. '>'))

    -- accordion-collapse
    local collapse_class = "accordion-collapse collapse"
    if is_open then
      collapse_class = collapse_class .. " show"
    end

    local parent_attr = ""
    if not multiple then
      parent_attr = ' data-bs-parent="#' .. accordion_id .. '"'
    end

    accordion_content:insert(pandoc.RawBlock(
      'html',
      string.format(
        '    <div id="%s" class="%s"%s aria-labelledby="%s">',
        collapse_id, collapse_class, parent_attr, header_id
      )
    ))

    -- accordion-body
    accordion_content:insert(pandoc.RawBlock('html', '      <div class="accordion-body">'))

    -- add panel content
    for _, content_el in ipairs(panel.content) do
      accordion_content:insert(content_el)
    end

    -- /accordion-body
    accordion_content:insert(pandoc.RawBlock('html', '      </div>'))
    -- /accordion-collapse
    accordion_content:insert(pandoc.RawBlock('html', '    </div>'))
    -- /accordion-item
    accordion_content:insert(pandoc.RawBlock('html', '  </div>'))
  end

  -- /accordion
  accordion_content:insert(pandoc.RawBlock('html', '</div>'))

  return accordion_content
end

function render_title(title, icon)
  local title_html = pandoc.write(pandoc.Pandoc(pandoc.Plain(title)), 'html')
  -- remove wrapping <p> tags if present
  title_html = title_html:gsub("^<p>", ""):gsub("</p>$", ""):gsub("^%s*", ""):gsub("%s*$", "")
  -- wrap title in a div to ensure proper spacing (button has display flex)
  title_html = '<div class="accordion-header-content">' .. title_html .. '</div>'

  return pandoc.RawBlock('html', render_icon(icon) .. title_html)
end

function render_icon(icon)
  if not icon or icon == "" then
    return ""
  end

  if icon:sub(1, 1) ~= "<" then
    -- HTML detected, return as-is with a space
    icon = '<i class="bi bi-' .. icon .. '"></i>'
  end

  return icon .. ' '
end

function has_bootstrap()
  if not quarto.format.is_html_output() then
    return false
  end

  local paramsText = os.getenv("QUARTO_FILTER_PARAMS")
  if paramsText == nil or paramsText == "" then
    return false
  end

  local paramsJson = quarto.base64.decode(paramsText)
  local quartoParams = quarto.json.decode(paramsJson)

  local value = quartoParams["has-bootstrap"]
  if value == nil then
    return false
  end

  return value
end

function Div(div)
  if not has_bootstrap() then
    return div
  end

  if not div.attr.classes:includes("panel-accordion") then
    return div
  end

  local panels, level, id = parse_accordion_contents(div)
  if panels and #panels > 0 then
    local accordion_blocks = render_accordion(div.attr, panels, level, id)
    return accordion_blocks
  else
    -- return original div if no panels found
    return div
  end
end

return {
  { Div = Div }
}
