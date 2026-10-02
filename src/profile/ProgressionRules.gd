extends RefCounted

const AVATARS := [
	{"id": "scout", "name": "Explorador", "level": 1},
	{"id": "medic", "name": "Rescate", "level": 1},
	{"id": "sentinel", "name": "Centinela", "level": 3},
	{"id": "viper", "name": "Víbora", "level": 5},
	{"id": "phoenix", "name": "Fénix", "level": 10},
	{"id": "elite", "name": "Élite Nexora", "level": 20},
]
const BANNERS := [
	{"id": "recruit", "name": "Primer amanecer", "level": 1, "cover": "campaign"},
	{"id": "defender", "name": "Última defensa", "level": 3, "cover": "waves"},
	{"id": "nightfall", "name": "Sin descanso", "level": 5, "cover": "endless"},
	{"id": "rival", "name": "Zona de combate", "level": 8, "cover": "pvp_ffa"},
	{"id": "brothers", "name": "Hasta el final", "level": 12, "cover": "pvp_duo"},
	{"id": "veteran", "name": "Veterano", "level": 20, "cover": "pvp_squad"},
]
const MISSIONS := [
	{"id": "daily_play", "name": "Completa una partida", "period": "daily", "metric": "matches", "target": 1, "xp": 100, "coins": 50},
	{"id": "daily_kills", "name": "Consigue 20 bajas", "period": "daily", "metric": "kills", "target": 20, "xp": 150, "coins": 75},
	{"id": "weekly_play", "name": "Completa 10 partidas", "period": "weekly", "metric": "matches", "target": 10, "xp": 500, "coins": 250},
	{"id": "weekly_wins", "name": "Consigue 3 victorias", "period": "weekly", "metric": "wins", "target": 3, "xp": 400, "coins": 200},
]

static func fresh() -> Dictionary:
	return {"xp": 0, "coins": 0, "gems": 0, "avatar": "scout", "banner": "recruit", "description": "DEADFALL", "missions": {}}

static func threshold(level: int) -> int:
	return 125 * level * (level - 1)

static func level_for(xp: int) -> int:
	var level := 1
	while level < 100 and xp >= threshold(level + 1): level += 1
	return level

static func public_fields(account: Dictionary) -> Dictionary:
	var level := level_for(int(account.get("xp", 0)))
	return {"level": level, "avatar": String(account.get("avatar", "scout")), "banner": String(account.get("banner", "recruit")), "description": String(account.get("description", "DEADFALL"))}

static func snapshot(account: Dictionary, now: int) -> Dictionary:
	var out := public_fields(account)
	out.merge({"xp": int(account.get("xp", 0)), "coins": int(account.get("coins", 0)), "gems": int(account.get("gems", 0)), "level_floor": threshold(int(out.level)), "next_level_xp": threshold(mini(100, int(out.level) + 1)), "avatars": AVATARS, "banners": BANNERS})
	out["missions"] = missions(account, now)
	return out

static func available(items: Array, id: String, level: int) -> bool:
	for item in items:
		if item.id == id: return int(item.level) <= level
	return false

static func period_key(period: String, now: int) -> int:
	var day := now / 86400
	return day if period == "daily" else (day + 3) / 7

static func missions(account: Dictionary, now: int) -> Array:
	var out: Array = []
	var states := Dictionary(account.get("missions", {}))
	for definition in MISSIONS:
		var item: Dictionary = definition.duplicate()
		var state := Dictionary(states.get(item.id, {}))
		var current := int(state.get("period_key", -1)) == period_key(item.period, now)
		item["progress"] = int(state.get("progress", 0)) if current else 0
		item["claimed"] = bool(state.get("claimed", false)) and current
		out.append(item)
	return out

# Input is a server-created history entry, not a client submission.
static func settle(account: Dictionary, entry: Dictionary) -> Dictionary:
	var reward := {"xp": 0, "coins": 0, "level_before": level_for(int(account.get("xp", 0))), "unlocked": [], "missions_completed": []}
	if String(entry.get("outcome", "ABORTED")) not in ["VICTORY", "DEFEAT", "DRAW"]: return reward
	var kills := clampi(int(entry.get("kills", 0)), 0, 1000)
	var seconds := clampi(int(entry.get("duration", 0)), 0, 7200)
	var waves := clampi(int(entry.get("wave", 0)), 0, 100)
	if seconds < 30 and kills == 0 and waves <= 1: return reward
	var win := String(entry.get("outcome")) == "VICTORY"
	reward.xp = mini(4000, seconds / 6 + kills * 12 + waves * 20 + (150 if win else 30))
	reward.coins = mini(1500, seconds / 12 + kills * 3 + waves * 5 + (60 if win else 10))
	var now := int(entry.get("completed_unix", Time.get_unix_time_from_system()))
	var states := Dictionary(account.get("missions", {})).duplicate(true)
	for definition in MISSIONS:
		var key := period_key(definition.period, now)
		var state := Dictionary(states.get(definition.id, {}))
		if int(state.get("period_key", -1)) != key: state = {"period_key": key, "progress": 0, "claimed": false}
		var increment := kills if definition.metric == "kills" else (1 if win else 0) if definition.metric == "wins" else 1
		state.progress = mini(int(definition.target), int(state.progress) + increment)
		if int(state.progress) >= int(definition.target) and not bool(state.claimed):
			state.claimed = true
			reward.xp += int(definition.xp)
			reward.coins += int(definition.coins)
			reward.missions_completed.append(definition.name)
		states[definition.id] = state
	account.missions = states
	account.xp = maxi(0, int(account.get("xp", 0))) + int(reward.xp)
	account.coins = maxi(0, int(account.get("coins", 0))) + int(reward.coins)
	reward["level_after"] = level_for(int(account.xp))
	for item in AVATARS + BANNERS:
		if int(item.level) > int(reward.level_before) and int(item.level) <= int(reward.level_after): reward.unlocked.append(item.name)
	return reward
