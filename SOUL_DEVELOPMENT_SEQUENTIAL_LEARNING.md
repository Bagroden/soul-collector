# Последовательное изучение способностей развития души

## Дата
28 октября 2025

## Проблема
Пользователь мог изучить любую способность в цепочке развития души, минуя предыдущие. Например, можно было изучить третью способность (Rare), не изучив первую (Common) и вторую (Uncommon).

## Решение
Добавлена система последовательного изучения способностей. Теперь каждая способность проверяет, изучена ли предыдущая в той же цепочке.

## Цепочки способностей

### 1. Эффективность восстановления (6 уровней)
- `restoration_efficiency_1` (Common) - доступна сразу
- `restoration_efficiency_2` (Uncommon) - требует `restoration_efficiency_1`
- `restoration_efficiency_3` (Rare) - требует `restoration_efficiency_2`
- `restoration_efficiency_4` (Epic) - требует `restoration_efficiency_3`
- `restoration_efficiency_5` (Legendary) - требует `restoration_efficiency_4`
- `restoration_efficiency_6` (Mythic) - требует `restoration_efficiency_5`

### 2. Заряды восстановления (6 уровней)
- `restoration_charges_1` (Common) - доступна сразу
- `restoration_charges_2` (Uncommon) - требует `restoration_charges_1`
- `restoration_charges_3` (Rare) - требует `restoration_charges_2`
- `restoration_charges_4` (Epic) - требует `restoration_charges_3`
- `restoration_charges_5` (Legendary) - требует `restoration_charges_4`
- `restoration_charges_6` (Mythic) - требует `restoration_charges_5`

### 3. Барьер восстановления (6 уровней)
- `restoration_barrier_1` (Common) - доступна сразу
- `restoration_barrier_2` (Uncommon) - требует `restoration_barrier_1`
- `restoration_barrier_3` (Rare) - требует `restoration_barrier_2`
- `restoration_barrier_4` (Epic) - требует `restoration_barrier_3`
- `restoration_barrier_5` (Legendary) - требует `restoration_barrier_4`
- `restoration_barrier_6` (Mythic) - требует `restoration_barrier_5`

### 4. Духовная мощь (5 уровней)
- `spiritual_power_1` (Common) - доступна сразу
- `spiritual_power_2` (Uncommon) - требует `spiritual_power_1`
- `spiritual_power_3` (Rare) - требует `spiritual_power_2`
- `spiritual_power_4` (Epic) - требует `spiritual_power_3`
- `spiritual_power_5` (Legendary) - требует `spiritual_power_4`

## Реализация

### Новая функция проверки
```gdscript
func _check_previous_soul_ability_learned(ability_id: String) -> Dictionary:
    """Проверяет, изучена ли предыдущая способность в цепочке развития души"""
    # Определяем тип способности и её номер
    var ability_type = ""
    var ability_number = 0
    
    # Парсим ID способности
    if "restoration_efficiency" in ability_id:
        ability_type = "restoration_efficiency"
        ability_number = int(ability_id.replace("restoration_efficiency_", ""))
    # ... для других типов
    
    # Первая способность всегда доступна
    if ability_number == 1:
        return {"can_learn": true, "reason": ""}
    
    # Проверяем предыдущую способность
    var previous_ability_id = ability_type + "_" + str(ability_number - 1)
    var previous_progress = ability_learning_system.get_ability_progress(previous_ability_id)
    var previous_learned = previous_progress.get("current_level", 0) >= 1
    
    if not previous_learned:
        return {
            "can_learn": false,
            "reason": "Сначала изучите предыдущую способность"
        }
    
    return {"can_learn": true, "reason": ""}
```

### Интеграция в UI
В функции `_create_ability_card()` добавлена проверка перед проверкой валюты:

```gdscript
if is_soul_ability:
    # Сначала проверяем предыдущую способность
    var previous_check = _check_previous_soul_ability_learned(ability.id)
    
    if not previous_check.can_learn:
        learn_button.text = previous_check.reason
        learn_button.disabled = true
    else:
        # Проверяем валюту
        var has_enough = _check_soul_ability_cost(ability.rarity)
        # ...
```

### Интеграция в логику изучения
В функции `_learn_soul_development_ability()` добавлена дополнительная проверка:

```gdscript
# Проверяем, изучена ли предыдущая способность
var previous_check = _check_previous_soul_ability_learned(ability_id)
if not previous_check.can_learn:
    _show_message_dialog("Недоступно", previous_check.reason)
    return
```

## Порядок проверок

При изучении способности проверки происходят в следующем порядке:

1. ✅ **Проверка изученности** - способность уже изучена?
2. ✅ **Проверка последовательности** - изучена ли предыдущая способность?
3. ✅ **Проверка валюты** - достаточно ли осколков душ и специальных душ?
4. ✅ **Списание валюты** - списываем валюту
5. ✅ **Изучение способности** - применяем эффект

## Примеры

### Пример 1: Попытка изучить вторую способность без первой
```
Способность: Восстановление души: Эффективность II (Uncommon)
Предыдущая: Восстановление души: Эффективность I (Common) - НЕ ИЗУЧЕНА

Результат:
- Кнопка: "Сначала изучите предыдущую способность" (заблокирована)
- Попытка изучения: Показывается диалог "Недоступно"
```

### Пример 2: Изучение второй способности после первой
```
Способность: Восстановление души: Эффективность II (Uncommon)
Предыдущая: Восстановление души: Эффективность I (Common) - ИЗУЧЕНА

Результат:
- Если есть валюта: Кнопка "Изучить (100 ОД)" (активна)
- Если нет валюты: Кнопка "Недостаточно валюты" (заблокирована)
```

## Визуальная индикация

### Способность доступна для изучения
- Кнопка: "Изучить ([стоимость])"
- Статус: Активна
- Условия:
  - Предыдущая способность изучена ✅
  - Достаточно валюты ✅

### Способность недоступна (нет предыдущей)
- Кнопка: "Сначала изучите предыдущую способность"
- Статус: Заблокирована
- Цвет: Серый

### Способность недоступна (нет валюты)
- Кнопка: "Недостаточно валюты"
- Статус: Заблокирована
- Условия:
  - Предыдущая способность изучена ✅
  - Недостаточно валюты ❌

### Способность изучена
- Кнопка: "Изучено"
- Статус: Заблокирована
- Фон: Зеленый с границей

## Независимость цепочек

Важно: цепочки способностей независимы друг от друга!

Например:
- Можно изучить `restoration_efficiency_1`, потом `restoration_charges_1`, потом `restoration_barrier_1`
- Можно изучить `restoration_efficiency_1`, `restoration_efficiency_2`, `restoration_efficiency_3` подряд
- Нельзя изучить `restoration_efficiency_3` без `restoration_efficiency_2`
- Но можно изучить `restoration_charges_3`, даже если не изучена `restoration_efficiency_3`

## Изменения в файлах

### Scripts/UI/AbilityLearningScreen.gd
**Добавлены:**
- `_check_previous_soul_ability_learned(ability_id: String) -> Dictionary` - проверка предыдущей способности

**Изменены:**
- `_create_ability_card()` - добавлена проверка последовательности перед проверкой валюты
- `_learn_soul_development_ability()` - добавлена проверка последовательности перед изучением

## Результат
✅ Теперь нельзя изучить способность, не изучив предыдущую в той же цепочке
✅ Кнопка изучения заблокирована с понятным сообщением
✅ Цепочки способностей независимы друг от друга
✅ Первые способности в каждой цепочке доступны сразу

