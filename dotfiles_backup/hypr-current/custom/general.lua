-- Monitor scale (force scale 1 so it is not zoomed)
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@144.42",
	position = "0x0",
	scale = 1,
})
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

-- Personal general settings (French AZERTY keyboard & touchpad)
-- Bordure active blanche avec halo lumineux subtil et minimaliste
hl.config({
	input = {
		kb_layout = "fr",
		follow_mouse = 1,
		touchpad = {
			natural_scroll = true,
		},
	},
	general = {
		border_size = 2,
		col = {
			active_border = "rgba(ffffffff)",
			inactive_border = "rgba(20202088)",
		},
	},
	decoration = {
		shadow = {
			enabled = true,
			range = 1,
			render_power = 2,
			color = "rgba(ffffff22)",
			color_inactive = "rgba(00000000)",
		},
	},
})
