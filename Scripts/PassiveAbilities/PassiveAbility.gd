# res://Scripts/PassiveAbilities/PassiveAbility.gd
extends Resource
class_name PassiveAbility

enum AbilityType {
	DEFENSIVE,    # Защитные (уворот, блок, регенерация)
	OFFENSIVE,    # Атакующие (кровотечение, крит, урон)
	UTILITY,      # Утилитарные (скорость, мана, опыт)
	SPECIAL       # Особые (магические, трансформации)
}

enum TriggerType {
	ON_ATTACK,        # При атаке
	ON_DAMAGE_TAKEN,  # При получении урона
	ON_TURN_START,    # В начале хода
	ON_TURN_END,      # В конце хода
	ON_DEATH,         # При смерти
	PASSIVE,          # Постоянно активная
	ON_CRIT,          # При критическом ударе
	ON_HEAL,          # При лечении
	ON_DODGE,         # При уклонении
	ON_ABILITY_USE    # При использовании способности
}

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var rarity: String = "common"  # common, uncommon, rare, epic, legendary, mythic
@export var ability_type: AbilityType = AbilityType.DEFENSIVE
@export var trigger_type: TriggerType = TriggerType.PASSIVE
@export var value: float = 0.0  # Основное значение (процент, урон, и т.д.)
@export var level_values: Array[float] = []  # Значения для каждого уровня (1, 2, 3)
@export var level_values_secondary: Array[float] = []  # Вторичные значения для каждого уровня (опционально)
@export var duration: float = 0.0  # Длительность эффекта (0 = постоянный)
@export var cooldown: float = 0.0  # Перезарядка способности
@export var max_stacks: int = 1  # Максимальное количество стаков
@export var tags: Array[String] = []  # Теги для группировки и поиска

var current_stacks: int = 0
var last_trigger_time: float = 0.0

func _init():
	pass

func can_trigger() -> bool:
	if cooldown > 0.0:
		var current_time = Time.get_time_dict_from_system()
		var time_since_last = current_time.hour * 3600 + current_time.minute * 60 + current_time.second - last_trigger_time
		return time_since_last >= cooldown
	return true

func trigger(owner: Node, target: Node = null, context: Dictionary = {}) -> Dictionary:
	if not can_trigger():
		return {"success": false, "message": "Ability on cooldown"}
	
	# Обновляем время последнего срабатывания
	var current_time = Time.get_time_dict_from_system()
	last_trigger_time = current_time.hour * 3600 + current_time.minute * 60 + current_time.second
	
	# Выполняем логику способности
	var result = execute_ability(owner, target, context)
	
	# Обновляем стаки
	if result.get("success", false):
		current_stacks = min(current_stacks + 1, max_stacks)
	
	return result

func execute_ability(_owner: Node, _target: Node = null, _context: Dictionary = {}) -> Dictionary:
	# Базовая реализация - должна быть переопределена в наследниках
	return {"success": false, "message": "Base ability - not implemented"}

func get_effect_description() -> String:
	var desc = description
	if value > 0:
		desc += " (" + str(value) + "%)"
	if duration > 0:
		desc += " на " + str(duration) + " ходов"
	return desc

func get_value_for_level(level: int) -> float:
	"""Возвращает значение способности для указанного уровня"""
	if level_values.size() == 0:
		return value  # Если нет уровней, возвращаем базовое значение
	
	var level_index = level - 1
	if level_index >= 0 and level_index < level_values.size():
		return level_values[level_index]
	
	# Если уровень выходит за границы, возвращаем последнее доступное значение
	return level_values[-1] if level_values.size() > 0 else value

func get_max_level() -> int:
	"""Возвращает максимальный уровень способности"""
	return level_values.size() if level_values.size() > 0 else 1

func has_levels() -> bool:
	"""Проверяет, есть ли у способности система уровней"""
	return level_values.size() > 0
