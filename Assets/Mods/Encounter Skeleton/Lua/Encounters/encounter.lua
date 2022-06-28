-- A basic encounter script skeleton you can copy and modify for your own creations.

-- music = "shine_on_you_crazy_diamond" --Either OGG or WAV. Extension is added automatically. Uncomment for custom music.
encountertext = "Poseur strikes a pose!" --Modify as necessary. It will only be read out in the action select screen.
nextwaves = {"bullettest_chaserorb"}
wavetimer = 4.0
arenasize = {155, 130}

enemies = {
"poseur"
}

enemypositions = {
{0, 0}
}

-- A custom list with attacks to choose from. Actual selection happens in EnemyDialogueEnding(). Put here in case you want to use it.
possible_attacks = {"bullettest_bouncy", "bullettest_chaserorb", "bullettest_touhou"}

function EncounterStarting()
    -- If you want to change the game state immediately, this is the place.

    --[[
    bullet = CreateSprite('bullet', 'Top')
    bullet.Scale(3,5)
    bullet.MoveTo(240, 200)
    bullet.rotation = 10
    bullet.shader.Test('CYF/QueueTest')

    bullet2 = CreateSprite('bullet', 'Top')
    bullet2.Scale(6,4)
    bullet2.MoveTo(380, 320)
    bullet2.rotation = -12
    bullet2.shader.Test('CYF/QueueTest')

    bg = CreateSprite('black', 'Bottom')

    hider = CreateSprite('px', 'Top')
    hider.Scale(640,480)
    hider.color = {1,0,0,0}

    grabber = CreateSprite('px', 'Top')
    grabber.Scale(640,480)
    grabber.shader.Test('CYF/QueueTestCopy')
    grabber.alpha = 0

    hider2 = CreateSprite('px', 'Top')
    hider2.Scale(640,480)
    hider2.alpha = 0

    paster = CreateSprite('px', 'Top')
    paster.Scale(640,-480)
    paster.shader.Test('CYF/QueueTestPaste')
    paster.alpha = 1
    ]]

    --[[
    px = CreateSprite('px', 'Top')
    px.Scale(640,480)
    px.shader.Test('CYF/QueueTestPaste2')
    ]]

    Misc.ScreenShader.Test('CYF/QueueTestPaste2')

end

function Update()

    --[[
    if Input.Right > 0 then
        paster.shader.SetFloat('Vertex1X', paster.shader.GetFloat('Vertex1X') + 4)
    elseif Input.Left > 0 then
        paster.shader.SetFloat('Vertex1X', paster.shader.GetFloat('Vertex1X') - 4)
    elseif Input.Up > 0 then
        paster.shader.SetFloat('Vertex1Y', paster.shader.GetFloat('Vertex1Y') + 4)
    elseif Input.Down > 0 then
        paster.shader.SetFloat('Vertex1Y', paster.shader.GetFloat('Vertex1Y') - 4)
    end
    ]]

end

function EnemyDialogueStarting()
    -- Good location for setting monster dialogue depending on how the battle is going.
end

function EnemyDialogueEnding()
    -- Good location to fill the 'nextwaves' table with the attacks you want to have simultaneously.
    nextwaves = { possible_attacks[math.random(#possible_attacks)] }
end

function DefenseEnding() --This built-in function fires after the defense round ends.
    encountertext = RandomEncounterText() --This built-in function gets a random encounter text from a random enemy.
end

function HandleSpare()
    State("ENEMYDIALOGUE")
end

function HandleItem(ItemID)
    BattleDialog({"Selected item " .. ItemID .. "."})
end