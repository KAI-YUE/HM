local M = {}

-----------------------------
--- new
----------------------------------
--- Helper: default formatter
local function _default_formatter(entry) return tostring(entry.text or entry.kind or "") end

--- Helper: entry text
local function _entry_text(log, entry)
    local formatter = entry.formatter or log.formatter or _default_formatter
    return formatter(entry)
end

function M.new(args)
    args = args or {}
    return {
        title       = args.title or "Log",
        empty_text  = args.empty_text or "No entries yet.",
        max_visible = args.max_visible or 8,
        entries     = {},
        formatter   = args.formatter,
    }
end

-----------------------------
--- add
----------------------------------
function M.add(log, entry)
    if not log then return end
    entry = entry or {}
    log.entries[#log.entries + 1] = entry
    return entry
end

-----------------------------
--- clear
----------------------------------
function M.clear(log)
    if not log then return end
    log.entries = {}
end

-----------------------------
--- text
----------------------------------
function M.text(log, args)
    if not log then return "" end
    args = args or {}
    local entries     = log.entries or {}
    local max_visible = args.max_visible or log.max_visible or 8
    local title       = args.title or log.title
    local lines       = {}
    if title and title ~= "" then lines[#lines + 1] = title end
    if #entries == 0 then
        lines[#lines + 1] = args.empty_text or log.empty_text or "No entries yet."
        return table.concat(lines, "\n")
    end

    local first = math.max(1, #entries - max_visible + 1)
    for idx = first, #entries do
        lines[#lines + 1] = tostring(idx) .. ". " .. _entry_text(log, entries[idx])
    end
    return table.concat(lines, "\n")
end

return M
