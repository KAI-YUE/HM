local M = {}

--- Helper: summary_text
function M.summary_text(meta)
    if not meta or meta.empty then return "no data" end
    local saved  = meta.saved_at and os.date("%Y-%m-%d   |    %H:%M", meta.saved_at) or "saved"
    local user   = meta.user_name or "player"
    return ("%s\n\n%s"):format(saved, user)
end

--- Helper: format_playtime
function M.format_playtime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local mins = math.floor(seconds / 60)
    return ("%dh %02dm"):format(math.floor(mins / 60), mins % 60)
end

--- Helper: playtime_text
function M.playtime_text(meta)
    if not meta or meta.empty then return "Playtime  --" end
    return ("Playtime  %s"):format(M.format_playtime(meta.playtime_s))
end

return M
