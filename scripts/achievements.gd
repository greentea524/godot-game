class_name Achievements

## Central definition of all 16 achievements (PG-64).
## Each achievement has a target and a Callable `goal` that reads current stats.
## Stats are expected to be a Dictionary containing the player's lifetime progress.

const LIST: Array[Dictionary] = [
	{
		"id": "coins_50",
		"name": "Pocket Change",
		"desc": "Collect 50 coins",
		"icon": "🪙",
		"goal": "_get_total_coins",
		"target": 50
	},
	{
		"id": "coins_100",
		"name": "Coin Collector",
		"desc": "Collect 100 coins",
		"icon": "💰",
		"goal": "_get_total_coins",
		"target": 100
	},
	{
		"id": "coins_500",
		"name": "Treasure Hunter",
		"desc": "Collect 500 coins",
		"icon": "👑",
		"goal": "_get_total_coins",
		"target": 500
	},
	{
		"id": "first_steps",
		"name": "First Steps",
		"desc": "Complete level 1-1",
		"icon": "👣",
		"goal": "_get_levels_completed",
		"target": 1
	},
	{
		"id": "world_traveler",
		"name": "World Traveler",
		"desc": "Complete a full world",
		"icon": "🗺️",
		"goal": "_get_levels_completed",
		"target": 3  # World 1 has 3 levels
	},
	{
		"id": "peak_performance",
		"name": "Peak Performance",
		"desc": "Reach World 5 — Frozen Peaks",
		"icon": "🏔️",
		"goal": "_get_levels_completed",
		"target": 12 # Worlds 1-4 have 3 levels each
	},
	{
		"id": "champion",
		"name": "Champion",
		"desc": "Complete all levels",
		"icon": "🏆",
		"goal": "_get_levels_completed",
		"target": 18 # 6 worlds * 3 levels
	},
	{
		"id": "stomper",
		"name": "Stomper",
		"desc": "Stomp 50 enemies",
		"icon": "👟",
		"goal": "_get_stomps",
		"target": 50
	},
	{
		"id": "persistent",
		"name": "Persistent",
		"desc": "Die 50 times",
		"icon": "💀",
		"goal": "_get_deaths",
		"target": 50
	},
	{
		"id": "fashionista",
		"name": "Fashionista",
		"desc": "Play as all 6 avatars",
		"icon": "🎨",
		"goal": "_get_avatars_used",
		"target": 6
	},
	{
		"id": "untouchable",
		"name": "Untouchable",
		"desc": "Clear a level without dying",
		"icon": "🛡️",
		"goal": "_get_death_free_clears",
		"target": 1
	},
	{
		"id": "flawless",
		"name": "Flawless",
		"desc": "Clear a full world without dying",
		"icon": "💎",
		"goal": "_get_death_free_worlds",
		"target": 1
	},
	{
		"id": "speedrunner",
		"name": "Speedrunner",
		"desc": "Clear a level in under 30 seconds",
		"icon": "⏱️",
		"goal": "_get_fast_clears",
		"target": 1
	},
	{
		"id": "lightning_run",
		"name": "Lightning Run",
		"desc": "Clear a level in under 15 seconds",
		"icon": "⚡",
		"goal": "_get_lightning_clears",
		"target": 1
	},
	{
		"id": "lava_dodger",
		"name": "Lava Dodger",
		"desc": "Clear World 3 without a lava death",
		"icon": "🌋",
		"goal": "_get_world_3_lava_free",
		"target": 1
	},
	{
		"id": "ice_legs",
		"name": "Ice Legs",
		"desc": "Clear World 5 without a freezing-water death",
		"icon": "🧊",
		"goal": "_get_world_5_water_free",
		"target": 1
	}
]

func _get_total_coins(s: Dictionary) -> int: return s.get("total_coins", 0)
func _get_levels_completed(s: Dictionary) -> int: return s.get("levels_completed", 0)
func _get_stomps(s: Dictionary) -> int: return s.get("stomps", 0)
func _get_deaths(s: Dictionary) -> int: return s.get("deaths", 0)
func _get_avatars_used(s: Dictionary) -> int: return s.get("avatars_used", []).size()
func _get_death_free_clears(s: Dictionary) -> int: return s.get("death_free_clears", 0)
func _get_death_free_worlds(s: Dictionary) -> int: return s.get("death_free_worlds", 0)
func _get_fast_clears(s: Dictionary) -> int: return s.get("fast_clears", 0)
func _get_lightning_clears(s: Dictionary) -> int: return s.get("lightning_clears", 0)
func _get_world_3_lava_free(s: Dictionary) -> int: return s.get("world_3_lava_free", 0)
func _get_world_5_water_free(s: Dictionary) -> int: return s.get("world_5_water_free", 0)

## Evaluates all achievements against the given stats.
## Returns an array of newly unlocked achievement IDs.
static func evaluate(stats: Dictionary, unlocked_ids: Dictionary) -> Array[String]:
	var newly_unlocked: Array[String] = []
	var instance = Achievements.new()
	for a in LIST:
		var id: String = a["id"]
		if unlocked_ids.has(id):
			continue
		var val: int = instance.call(a["goal"], stats)
		if val >= a["target"]:
			newly_unlocked.append(id)
	return newly_unlocked

static func get_by_id(id: String) -> Dictionary:
	for a in LIST:
		if a["id"] == id:
			return a
	return {}
