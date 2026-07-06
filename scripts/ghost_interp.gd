class_name GhostInterp
extends RefCounted
## Ghost interpolation — a direct port of the JS platformer's ghosts.js.
## Remote players arrive at ~15 Hz; we render them ~100 ms in the past
## and lerp between the two bracketing snapshots so motion stays smooth.
## When the next packet is late we extrapolate along the last velocity
## for a capped window instead of freezing. Pure functions (no nodes),
## so the timing logic is unit-testable headlessly.

const INTERP_DELAY := 100.0     # ms in the past we render ghosts
const MAX_EXTRAPOLATE := 200.0  # ms to glide on last velocity past newest snap
const MAX_SNAPSHOTS := 20

## Append a received snapshot stamped with local receive time (ms).
static func push(buffer: Array, snap: Dictionary, now: float) -> void:
	var entry := snap.duplicate()
	entry["t"] = now
	buffer.append(entry)
	while buffer.size() > MAX_SNAPSHOTS:
		buffer.pop_front()


## Sample the buffer at (now - delay), lerping position between the two
## snapshots bracketing that render time. Returns an empty Dictionary
## until there is any data. Discrete fields (facing/anim/lvl) come from
## the earlier snapshot so they line up with the drawn position.
static func sample(buffer: Array, now: float, delay := INTERP_DELAY) -> Dictionary:
	if buffer.is_empty():
		return {}
	var render_t := now - delay
	var first: Dictionary = buffer[0]
	var last: Dictionary = buffer[buffer.size() - 1]

	if render_t <= first["t"]:
		return first.duplicate()

	# Past the newest snapshot: extrapolate along the last velocity for a
	# capped window so the ghost glides through packet gaps.
	if render_t >= last["t"]:
		var ahead: float = minf(render_t - last["t"], MAX_EXTRAPOLATE) / 1000.0
		var ext_view := last.duplicate()
		ext_view["x"] = last["x"] + last.get("vx", 0.0) * ahead
		return ext_view

	# Interpolate between the two snapshots bracketing render_t.
	var a: Dictionary = first
	var b: Dictionary = last
	for i in range(buffer.size() - 1):
		if buffer[i]["t"] <= render_t and render_t <= buffer[i + 1]["t"]:
			a = buffer[i]
			b = buffer[i + 1]
			break
	var span: float = b["t"] - a["t"]
	var f: float = (render_t - a["t"]) / span if span > 0.0 else 0.0
	var view := a.duplicate()
	view["x"] = a["x"] + (b["x"] - a["x"]) * f
	view["y"] = a["y"] + (b["y"] - a["y"]) * f
	return view
