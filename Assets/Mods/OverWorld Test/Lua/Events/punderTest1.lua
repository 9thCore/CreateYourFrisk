function EventPage1()
    local spriteTest = Event.GetSprite("Punder1")
    local playerpos = Event.GetPosition("Player")
    local eventpos = Event.GetPosition("Punder1")
    local diff = { eventpos[1] - playerpos[1], eventpos[2] - playerpos[2] }
    local angle = (math.atan2(diff[1], diff[2]) + (math.pi*2)) % (math.pi*2)
    --DEBUG(tostring(angle/math.pi) .. "π")
    local dirword = "Down"
    if     angle > math.pi/4   and angle <= 3*math.pi/4 then dirword = "Left"
    elseif angle > 3*math.pi/4 and angle <= 5*math.pi/4 then dirword = "Up"
    elseif angle > 5*math.pi/4 and angle <= 7*math.pi/4 then dirword = "Right"
    end
	spriteTest.Set("Overworld/Punder" .. dirword .. "1")
    local text = ""
    if Event.GetAnimHeader("Player") == "MK" then        text = "Hello there little buddy!"
    elseif Event.GetAnimHeader("Player") == "Chara" then text = "Hey[waitall:5]...[waitall:1]you look kinda menacing[waitall:5]...[waitall:1][w:30]\nBe good, [w:20]alright?"
    else                                                 text = "Hey, [w:20]how's going?"
    end
	General.SetDialog({"[voice:punderbolt]" .. text}, true, {"pundermug"})
	spriteTest.Set("Overworld/PunderDown1")
end