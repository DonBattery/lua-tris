local BGM = love.audio.newSource("assets/endless.mp3", "stream")
BGM:setLooping(true)
BGM:setVolume(0.1)

function ToggleBGM()
    if BGM:isPlaying() then
       BGM:pause()
    else
        BGM:play()
    end
end

local function effect(source)
    local src = love.audio.newSource(source, "static")
    src:setVolume(0.5)
    return {
        sound = src,
        hasPlayed = false,
        play = function (self, mode)
            if mode == "once" then
                if not self.hasPlayed and not self.sound:isPlaying() then
                    self.hasPlayed = true
                    self.sound:play()
                end
            elseif mode =="separate" then
                if not self.sound:isPlaying() then
                    self.hasPlayed = true
                    self.sound:play()
                end
            else
                self.hasPlayed = true
                self.sound:stop()
                self.sound:play()
            end
        end
    }
end

Effects = {
    whoosh = effect("assets/whoosh.wav"),
    select = effect("assets/select.wav"),
}


return {
    ToggleBGM = ToggleBGM,
    Effects   = Effects,
}