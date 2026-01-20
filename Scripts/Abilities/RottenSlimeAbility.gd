# res://Scripts/Abilities/RottenSlimeAbility.gd
extends Node

var id: String = "rotten_slime_blast"                    # ⚠️ ВАЖНО: Уникальный ID
var name: String = "Гнилостный взрыв"             # ⚠️ ВАЖНО: Отображаемое имя
var description: String = "Мощная атака с наложением гнили"
var stamina_cost: int = 30                     # ⚠️ ВАЖНО: Стоимость выносливости
var damage_type: String = "physical"           # ⚠️ ВАЖНО: Тип урона

func execute_ability(owner: Node, target: Node = null) -> Dictionary:
    if not target:
        return {"success": false, "message": "Нет цели для гнилостного взрыва"}
    
    # Проверяем, достаточно ли выносливости
    if owner.current_stamina < stamina_cost:
        return {"success": false, "message": "Недостаточно выносливости для гнилостного взрыва"}
    
    # Тратим выносливость
    owner.current_stamina -= stamina_cost
    
    # Рассчитываем урон: сила + ловкость
    var damage = owner.strength + owner.agility
    
    # Наносим урон цели
    if target.has_method("take_damage"):
        var actual_damage = target.take_damage(damage)
        
        return {
            "success": true,
            "message": owner.display_name + " наносит гнилостный взрыв " + target.display_name + " на " + str(actual_damage) + " урона!",
            "damage": actual_damage,
            "stamina_cost": stamina_cost,
            "ability": "rotten_slime_blast"
        }
    
    return {"success": false, "message": "Цель не может получить урон"}
