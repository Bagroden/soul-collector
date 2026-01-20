# 🚀 Быстрое руководство: Добавление эффекта анимации для способности врага

## 📋 Краткая инструкция (5 шагов)

### Шаг 1: Добавьте анимацию в PlayerBody
1. Откройте `Scenes/Battle/PlayerBody.tscn`
2. Выберите узел `Visual` → `Sprite Frames`
3. Добавьте анимацию с именем `{ability_id}_anim` (например, `rat_bite_anim`)
4. Назначьте спрайты, установите `Loop = false`

### Шаг 2: Добавьте в список экспорта
Откройте `Scripts/Tools/ExportAbilityAnimations.gd` и добавьте имя анимации:

```gdscript
const ABILITY_ANIMATIONS = [
    # ... существующие анимации ...
    "your_new_anim"  # ← Добавьте сюда
]
```

### Шаг 3: Экспортируйте анимацию
- **Редактор** → **Выполнить скрипт** → `Scripts/Tools/ExportAbilityAnimationsEditor.gd`
- Или через консоль:
```gdscript
var exporter = preload("res://Scripts/Tools/ExportAbilityAnimations.gd").new()
exporter.export_ability_animations()
```

### Шаг 4: Добавьте маппинг
Откройте `Data/AbilityAnimations.tres` и добавьте:

```tres
ability_animations = {
    "your_ability_id": "your_new_anim",  # ← Добавьте запись
    ...
}
```

**Важно:** `ability_id` должен совпадать с ID в `EnemyAbilities.gd`!

### Шаг 5: Используйте в коде
В `battle_manager.gd`, в функции `_enemy_action()`, добавьте:

```gdscript
elif result.get("your_ability_id", false):
    await get_tree().create_timer(0.35).timeout
    
    if ability_effect_manager:
        ability_effect_manager.play_ability_effect_on_target(
            player_node, 
            "your_ability_id", 
            Vector2.ZERO, 
            Vector2(2, 2), 
            100
        )
    
    # Наносим урон...
```

---

## ✅ Чеклист

- [ ] Анимация добавлена в `PlayerBody.tscn` → `Visual` → `Sprite Frames`
- [ ] Имя анимации: `{ability_id}_anim`
- [ ] Анимация добавлена в `ABILITY_ANIMATIONS` в `ExportAbilityAnimations.gd`
- [ ] Анимация экспортирована в `AbilityEffectAnimations.tres`
- [ ] Маппинг добавлен в `AbilityAnimations.tres`
- [ ] ID способности совпадает в `EnemyAbilities.gd` и `AbilityAnimations.tres`
- [ ] Код добавлен в `battle_manager.gd`
- [ ] Протестировано в игре

---

## 📝 Пример: Добавление эффекта "Огненный удар"

### 1. В PlayerBody.tscn:
- Анимация: `fire_strike_anim`

### 2. В ExportAbilityAnimations.gd:
```gdscript
const ABILITY_ANIMATIONS = [
    # ... другие ...
    "fire_strike_anim"  # ← Добавлено
]
```

### 3. Экспорт (через меню или консоль)

### 4. В AbilityAnimations.tres:
```tres
ability_animations = {
    "fire_strike": "fire_strike_anim",  # ← Добавлено
    ...
}
```

### 5. В EnemyAbilities.gd:
```gdscript
var fire_ability = EnemyAbility.new()
fire_ability.id = "fire_strike"  # ← Должно совпадать с ключом в AbilityAnimations.tres
```

### 6. В battle_manager.gd:
```gdscript
elif result.get("fire_strike", false):
    await get_tree().create_timer(0.35).timeout
    
    if ability_effect_manager:
        ability_effect_manager.play_ability_effect_on_target(
            player_node, 
            "fire_strike", 
            Vector2.ZERO, 
            Vector2(2, 2), 
            100
        )
    
    var player_old_hp = player_node.hp
    player_node.take_damage(damage, damage_type)
    var actual_damage = player_old_hp - player_node.hp
    DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
```

---

## 🐛 Частые ошибки

### ❌ Эффект не проигрывается
- Проверьте, что `ability_id` совпадает везде
- Проверьте логи в консоли на наличие ошибок
- Убедитесь, что анимация экспортирована в `AbilityEffectAnimations.tres`

### ❌ Неправильный ID способности
- В `EnemyAbilities.gd`: `ability.id = "fire_strike"`
- В `AbilityAnimations.tres`: `"fire_strike": "fire_strike_anim"`
- В `battle_manager.gd`: `result.get("fire_strike", false)`

### ❌ Анимация не найдена
- Убедитесь, что анимация экспортирована
- Проверьте имя анимации в `AbilityEffectAnimations.tres`
- Убедитесь, что маппинг правильный в `AbilityAnimations.tres`

---

## 📚 Подробная документация

Для более подробной информации см.:
- **`UNIVERSAL_ABILITY_EFFECT_SYSTEM.md`** - полное описание системы
- **`ABILITY_EFFECT_SYSTEM_SETUP.md`** - настройка системы
- **`ABILITY_EFFECT_ANIMATION_GUIDE.md`** - руководство по анимациям

---

**Последнее обновление:** 2024
