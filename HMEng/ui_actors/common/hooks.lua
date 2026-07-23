local M = {}

---____________________________
--- main: run_hook
---______________________________________
function M.run_hook(source, gm)
    local cfg, hook = source.config or {}, source.config and source.config.hook_fn
    if type(hook) == "function" then return hook(gm, source) end
    if type(hook) == "string" and gm.Fs and gm.Fs[hook] then return gm.Fs[hook](gm, source) end
    if cfg.intent and gm.CTRL then return gm.CTRL:emit_intent(cfg.intent, { source = source }) end
end

return M
