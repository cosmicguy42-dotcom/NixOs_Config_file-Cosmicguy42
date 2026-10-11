#!/usr/bin/env python3
"""Palette post-processing + template rendering for the "nothing" shell.

matugen averages the wallpaper, which gives harmonious but muddy surfaces.
Here we keep its accent tones but can:
  - neutralise the surfaces (near-black / near-white, Nothing-style), or
  - use a hand-picked base, surface and accent instead,
then render every template listed in ../matugen/config.toml ourselves.

usage: render.py <matugen-json> <state-json>
"""
import colorsys
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.join(HERE, "..", "matugen", "config.toml")

palette_json, state_json = sys.argv[1], sys.argv[2]
m = json.load(open(palette_json))
state = json.load(open(state_json))
mode = state.get("mode", "dark")
dark = mode != "light"
colors = {k: v["default"]["color"] for k, v in m["colors"].items()}


def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def hexc(c):
    return "#" + "".join(f"{round(max(0, min(1, v)) * 255):02x}" for v in c)


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return hexc([x + (y - x) * t for x, y in zip(a, b)])


def lum(h):
    def ch(v):
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (ch(v) for v in rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def readable_on(h):
    return "#111111" if lum(h) > 0.4 else "#ffffff"


def surfaces(base, surface):
    """Ramp of surface roles from a base (window/pill) and a surface (cards)."""
    light = lum(base) > 0.4
    ink = "#111111" if light else "#f2f2f2"
    step = "#000000" if light else "#ffffff"
    return {
        "surface_container_lowest": base,
        "background": base,
        "surface": base,
        "surface_dim": base,
        "surface_container_low": mix(base, surface, 0.5),
        "surface_container": surface,
        "surface_container_high": mix(surface, step, 0.05),
        "surface_container_highest": mix(surface, step, 0.10),
        "surface_bright": mix(surface, step, 0.14),
        "surface_variant": mix(surface, step, 0.10),
        "on_surface": ink,
        "on_background": ink,
        "on_surface_variant": mix(ink, base, 0.38),
        "outline": mix(ink, base, 0.6),
        "outline_variant": mix(ink, base, 0.82),
        "inverse_surface": ink,
        "inverse_on_surface": base,
        "scrim": "#000000",
        "shadow": "#000000",
    }


source = state.get("source", "wallpaper")
if source == "custom":
    c = state.get("custom", {})
    base = c.get("base", "#000000")
    surface = c.get("surface", "#141414")
    accent = c.get("accent", "#d71921")
    colors.update(surfaces(base, surface))
    colors["primary"] = accent
    colors["on_primary"] = readable_on(accent)
    colors["surface_tint"] = accent
    colors["primary_container"] = mix(accent, base, 0.6)
    colors["on_primary_container"] = mix(accent, colors["on_surface"], 0.6)
elif source == "cover" or state.get("neutral", True):
    # Keep matugen's accent family, drop the tinted mud from the surfaces.
    if dark:
        colors.update(surfaces("#050505", "#141414"))
    else:
        colors.update(surfaces("#ffffff", "#f0f0f0"))

colors["mode"] = mode  # not a colour; handy for templates reading it


# --- Render templates (the subset of matugen syntax our templates use)
def render(text):
    def loop(match):
        body = match.group(1)
        out = []
        for name, value in colors.items():
            if name == "mode":
                continue
            out.append(body.replace("{{name}}", name).replace("{{value.default.hex}}", value))
        return "".join(out)

    text = re.sub(r"<\* for name, value in colors \*>(.*?)<\* endfor \*>", loop, text, flags=re.S)
    text = re.sub(r"\{\{\s*colors\.(\w+)\.default\.hex_stripped\s*\}\}", lambda x: colors[x.group(1)].lstrip("#"), text)
    text = re.sub(r"\{\{\s*colors\.(\w+)\.default\.hex\s*\}\}", lambda x: colors[x.group(1)], text)
    text = text.replace("{{image}}", state.get("wallpaper", "")).replace("{{mode}}", mode)
    return text


toml = open(CONFIG).read()
for block in re.findall(r"\[templates\.\w+\](.*?)(?=\n\[|\Z)", toml, flags=re.S):
    inp = re.search(r"input_path\s*=\s*'([^']+)'", block).group(1)
    out = re.search(r"output_path\s*=\s*'([^']+)'", block).group(1)
    inp, out = os.path.expanduser(inp), os.path.expanduser(out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    rendered = render(open(inp).read())
    with open(out, "w") as f:  # in place: keeps Quickshell's file watchers
        f.write(rendered)
