local UTF8 = { pattern = "[%z\1-\127\194-\244][\128-\191]*" }

-------------------------------------------------------------
--- Map
-------------------------------------------------------------
function UTF8.map(s, f, no_subs)
    local i = 0
    if no_subs then
        for b, e in s:gmatch("()" .. UTF8.pattern .. "()") do
            i = i + 1;  local c = e - b; f(i, c, b); return
        end
    end

    for b, c in s:gmatch("()(" .. UTF8.pattern .. ")") do
        i = i + 1;      f(i, c, b)
    end
end

--------------------------------------
--- Chars: a wrapper for chars
---------------------------------------
function UTF8.chars(s, no_subs) return coroutine.wrap(function () return UTF8.map(s, coroutine.yield, no_subs) end) end

return UTF8