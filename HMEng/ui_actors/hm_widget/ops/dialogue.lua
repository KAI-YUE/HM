local TextReveal = require("HMEng.ui_actors.hm_widget.renderers.text.text_reveal")

local Y, N = true, false

return function(HMWidget)

function HMWidget:advance_dialogue_page()
    local cfg = self.config;        if cfg.type ~= "dialogue_box" or not cfg.text_wrap then return N end

    self:update_text()
    if cfg.text_reveal and not TextReveal.is_complete(cfg) then
        TextReveal.skip_to_end(cfg)
        self:update_text()
        return Y
    end

    local pages = cfg.text_pages
    if not pages or (cfg.text_page or 1) >= #pages then return N end

    cfg.text_page = (cfg.text_page or 1) + 1
    cfg.text_reveal_source = nil
    self:update_text()
    return Y
end

end
