# qutebrowser: defaults, plus the palette's colors (colors.py, rendered by `theme`) and the
# desktop's fonts. Settings changed from the UI are not kept (autoconfig off): this file is the config.
# pylint: disable=undefined-variable  (c and config are injected by qutebrowser)
config.load_autoconfig(False)
config.source("colors.py")

c.fonts.default_family = ["Inter"]
c.fonts.default_size = "11pt"
c.fonts.web.family.fixed = "JetBrainsMono Nerd Font"
