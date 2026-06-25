_RELEASE_MODE = false
_DEMO = false
Ver = "0.1"
_SEED = "CHLOE"


function love.conf(t)
	t.title    = "Henshin Meshi"
    local _tw  = t.window

	_tw.width,    _tw.height    = 0,   0
	_tw.minwidth, _tw.minheight = 100, 100
end 
