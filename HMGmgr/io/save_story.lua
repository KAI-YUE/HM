return function(GMgr)
-----------------------------
--- Save slot story state
----------------------------------
--- Helper: default_story_state
function GMgr:default_story_state()
    return {
        dialogue = { ["ch01.alice.first_meeting"] = { line = 1 } },
        flags = {},
        pointers = {},
    }
end

--- Helper: story_state_ref
function GMgr:story_state_ref()
    self.story_state            = self.story_state or self:default_story_state()
    self.story_state.dialogue   = self.story_state.dialogue or {}
    self.story_state.flags      = self.story_state.flags or {}
    self.story_state.pointers   = self.story_state.pointers or {}
    return self.story_state
end

-----------------------------
--- dialogue line ptr
----------------------------------
--- Helper: dialogue_line_ptr
function GMgr:dialogue_line_ptr(dialogue_key)
    local story = self:story_state_ref()
    local dptr  = story.dialogue[dialogue_key]
    if not dptr then dptr = { line = 1 }; story.dialogue[dialogue_key] = dptr end
    return dptr
end

-----------------------------
--- advance dialogue line ptr
----------------------------------
--- Helper: advance_dialogue_line_ptr
function GMgr:advance_dialogue_line_ptr(dialogue_key, delta)
    local dptr = self:dialogue_line_ptr(dialogue_key)
    dptr.line = (tonumber(dptr.line) or 1) + (delta or 1)
    if dptr.line < 1 then dptr.line = 1 end
    return dptr.line
end

end
