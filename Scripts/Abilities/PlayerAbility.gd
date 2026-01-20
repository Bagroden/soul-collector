# res://Scripts/Abilities/PlayerAbility.gd
extends Resource
class_name PlayerAbility

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var mp_cost: int = 0
@export var stamina_cost: int = 0
@export var cooldown: int = 0  # Ходы до следующего использования
var damage_type: String = "physical"  # physical, magic или poison

func can_use(owner: Node) -> bool:
	"""Проверяет, может ли владелец использовать способность"""
	if mp_cost > 0 and owner.mp < mp_cost:
		return false
	if stamina_cost > 0 and owner.stamina < stamina_cost:
		return false
	return true

func use_ability(owner: Node, target: Node) -> Dictionary:
	"""Использует способность"""
	if not can_use(owner):
		return {"success": false, "message": "Недостаточно ресурсов для использования способности"}
	
	# Тратим ресурсы
	if mp_cost > 0:
		owner.mp = max(0, owner.mp - mp_cost)
	if stamina_cost > 0:
		owner.stamina = max(0, owner.stamina - stamina_cost)
	
	# Рассчитываем урон (будет переопределено в конкретных способностях)
	var damage = calculate_damage(owner, target)
	
	# Определяем шанс критического удара в зависимости от типа урона
	var crit_chance = 0.0
	if damage_type == "magic":
		if owner.has_method("get_magic_crit_chance"):
			crit_chance = owner.get_magic_crit_chance() / 100.0
		else:
			# Альтернативная проверка через PlayerData
			if owner.has_method("get") and "intelligence" in owner:
				var magic_crit = 5 + owner.intelligence  # Базовая формула
				crit_chance = magic_crit / 100.0
			else:
				crit_chance = owner.crit_chance / 100.0
	else:
		crit_chance = owner.crit_chance / 100.0
	
	var is_crit = randf() < crit_chance
	
	if is_crit:
		damage = int(damage * 1.5)  # Критический урон
	
	return {
		"success": true,
		"damage": damage,
		"is_crit": is_crit,
		"damage_type": damage_type,
		"message": owner.display_name + " использует " + name + "!"
	}

func calculate_damage(_owner: Node, _target: Node) -> int:
	"""Рассчитывает урон способности (переопределяется в наследниках)"""
	# Базовый урон - переопределяется в наследниках
	return 0
