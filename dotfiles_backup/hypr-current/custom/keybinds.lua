-- Custom keybindings
hl.bind("SUPER + KP_Enter", hl.dsp.exec_cmd(terminal), { description = "App: Terminal (Keypad Enter)" })
hl.bind("SUPER + Z", hl.dsp.exec_cmd(browser), { description = "App: Browser (Zen)" })
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager), { description = "App: File manager (Nautilus)" })
hl.bind("SUPER + Y", hl.dsp.exec_cmd("kitty yazi"), { description = "App: Yazi (TUI)" })

-- Envoyer la fenêtre vers un espace de travail spécifique (SUPER + SHIFT + 1..10)
for i = 1, 10 do
	local target = (i % 10)
	hl.bind("SUPER + SHIFT + " .. target, function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i) }))
	end, { description = "Window: Send to workspace " .. i })
end

-- Support disposition AZERTY française (touches physiques & é " ' ( - è _ ç à)
for i = 1, 10 do
	local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
	hl.bind("SUPER + SHIFT + code:" .. numberkey[i], function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i) }))
	end, { description = "Window: Send to workspace " .. i .. " (AZERTY)" })
end

-- Pavé numérique (Numpad 1..9, 0)
for i = 1, 10 do
	local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
	hl.bind("SUPER + SHIFT + code:" .. numpadkey[i], function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i) }))
	end, { description = "Window: Send to workspace " .. i .. " (Numpad)" })
end

-- Déplacer et réorganiser la fenêtre sur le MÊME espace de travail (ordre des tuiles)
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "l" }), { description = "Window: Move Left" })
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "r" }), { description = "Window: Move Right" })
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "u" }), { description = "Window: Move Up" })
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "d" }), { description = "Window: Move Down" })
