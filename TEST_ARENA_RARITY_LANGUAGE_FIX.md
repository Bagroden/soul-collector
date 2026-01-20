# Исправление проблемы с языком редкости в тестовой арене

## Проблема
В тестовой арене при выборе Крысы с редкостью "легендарный" возникает ошибка из-за несоответствия языков:
- **TestArena использует русский язык**: "легендарный"
- **Конфигурация использует английский язык**: "legendary"

## Анализ лога
```
rarity: 'легендарный'  ❌ Русский язык
Доступные редкости для Крыса: ["common", "uncommon", "rare", "epic", "legendary", "elite"]  ✅ Английский язык
rarity in enemy_passives[enemy_name]: false  ❌ Не совпадает
```

## Корневая причина
**Проблема с языком редкости:**
- В TestArena используется русский язык для отображения редкости
- В конфигурации пассивных способностей используется английский язык
- Сравнение строк не работает из-за разных языков

## Исправление

### 1. Добавлен метод преобразования редкости
```gdscript
func _convert_rarity_to_english(russian_rarity: String) -> String:
    """Преобразует редкость с русского на английский"""
    match russian_rarity:
        "обычный":
            return "common"
        "необычный":
            return "uncommon"
        "редкий":
            return "rare"
        "эпический":
            return "epic"
        "легендарный":
            return "legendary"
        "элитный":
            return "elite"
        "босс":
            return "boss"
        _:
            print("❌ ОШИБКА: Неизвестная редкость: ", russian_rarity)
            return "common"  # Fallback к common
```

### 2. Изменен метод _set_global_test_variables()
```gdscript
func _set_global_test_variables():
    # Преобразуем редкость с русского на английский
    var english_rarity = _convert_rarity_to_english(selected_rarity)
    print("Преобразованная редкость: ", english_rarity)
    
    # Используем английскую редкость
    test_globals.test_enemy_rarity = english_rarity
```

## Как работает исправление

### До исправления:
1. TestArena → `selected_rarity = "легендарный"` (русский)
2. TestArena → `test_enemy_rarity = "легендарный"` (русский)
3. BattleManager → `get_passives_for_enemy("Крыса", "легендарный")` ❌
4. Конфигурация → `enemy_passives["Крыса"]["legendary"]` (английский) ❌
5. Результат: `"легендарный" != "legendary"` → false ❌

### После исправления:
1. TestArena → `selected_rarity = "легендарный"` (русский)
2. TestArena → `_convert_rarity_to_english("легендарный")` → `"legendary"` ✅
3. TestArena → `test_enemy_rarity = "legendary"` (английский) ✅
4. BattleManager → `get_passives_for_enemy("Крыса", "legendary")` ✅
5. Конфигурация → `enemy_passives["Крыса"]["legendary"]` (английский) ✅
6. Результат: `"legendary" == "legendary"` → true ✅

## Ожидаемый результат
Теперь в консоли должно быть:
```
=== УСТАНОВКА ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ ТЕСТОВОГО РЕЖИМА ===
selected_rarity: легендарный
Преобразованная редкость: legendary
✅ Глобальные переменные установлены
test_enemy_rarity: legendary

=== ОТЛАДКА get_passives_for_enemy ===
enemy_name: 'Крыса'
rarity: 'legendary'
enemy_name in enemy_passives: true
Доступные редкости для Крыса: ["common", "uncommon", "rare", "epic", "legendary", "elite"]
rarity in enemy_passives[enemy_name]: true
=====================================
```

## Преимущества решения
1. **Обратная совместимость** - русский интерфейс остается
2. **Правильная работа** - английская конфигурация работает
3. **Автоматическое преобразование** - не нужно менять конфигурацию
4. **Fallback** - неизвестные редкости преобразуются в "common"

## Поддерживаемые редкости
- "обычный" → "common"
- "необычный" → "uncommon"
- "редкий" → "rare"
- "эпический" → "epic"
- "легендарный" → "legendary"
- "элитный" → "elite"
- "босс" → "boss"

---

**Автор**: Claude AI Assistant  
**Дата**: 2024  
**Версия**: 1.0
