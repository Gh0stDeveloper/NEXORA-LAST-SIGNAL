extends RefCounted

const MAX_LENGTH := 160

static func clean(value: String) -> String:
	var out := ""
	for ch in value.left(MAX_LENGTH):
		if ch.unicode_at(0) >= 32 or ch == "\n": out += ch
	out = out.strip_edges()
	return "DEADFALL" if out.is_empty() else out

# Convert only our small whitelist, never feed arbitrary user BBCode to Godot.
# Legacy seven-digit colors are completed on the right: FFFF000 -> FFFF0000.
static func render(value: String) -> String:
	var source := clean(value)
	var bold := false
	var italic := false
	var color := ""
	var out := ""
	var index := 0
	while index < source.length():
		if source[index] == "[":
			var end := source.find("]", index)
			if end > index and end - index <= 10:
				var tag := source.substr(index + 1, end - index - 1)
				var recognized := true
				match tag.to_lower():
					"b": bold = true
					"/b": bold = false
					"i": italic = true
					"/i": italic = false
					"c": pass
					"/c", "-": color = ""
					"reset":
						bold = false
						italic = false
						color = ""
					_:
						if tag.length() in [6, 7, 8] and tag.is_valid_hex_number(false):
							if tag.length() == 7: tag += "0"
							color = tag.substr(2, 6) if tag.length() == 8 else tag
						else: recognized = false
				if recognized:
					index = end + 1
					continue
		var ch := "[lb]" if source[index] == "[" else source[index]
		out += ("[b]" if bold else "") + ("[i]" if italic else "") + ("[color=#%s]" % color if not color.is_empty() else "")
		out += ch
		out += ("[/color]" if not color.is_empty() else "") + ("[/i]" if italic else "") + ("[/b]" if bold else "")
		index += 1
	return out
