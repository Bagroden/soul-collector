# Отчет об отладке пассивных способностей

## Проблема
Пассивные способности врагов на тестовой арене не работают или отсутствуют.

## Анализ лога

### Обнаруженные проблемы:
1. **Пассивные способности не срабатывают** - "Гоблин Воин - Уворот (не сработала)"
2. **Ошибка "BattleManager не найден в сцене боя"** - может влиять на работу пассивных способностей
3. **Враг использует только "Базовая атака"** вместо активных способностей
4. **Конфигурация найдена** - "rarity in enemy_passives[enemy_name]: true"

### Анализ конфигурации:
```
rarity: 'legendary'
enemy_name in enemy_passives: true
Доступные редкости для Гоблин Воин: ["common", "uncommon", "rare", "epic", "legendary", "elite", "boss"]
rarity in enemy_passives[enemy_name]: true
```

**Вывод:** Конфигурация пассивных способностей найдена и корректна.

## Возможные причины

### 1. **Проблема с именем врага**
- В сцене: `display_name = "Гоблин Воин"`
- В конфигурации: `"Гоблин Воин"`
- **Статус:** Имена совпадают ✅

### 2. **Проблема с BattleManager**
- Ошибка: "BattleManager не найден в сцене боя"
- **Возможная причина:** Пассивные способности не могут найти BattleManager для работы

### 3. **Проблема с инициализацией пассивных способностей**
- Пассивные способности могут не инициализироваться правильно
- Возможно, проблема в порядке загрузки компонентов

## Добавленная отладка

### Улучшенная функция `get_passives_for_enemy`:
```gdscript
func get_passives_for_enemy(enemy_name: String, rarity: String) -> Array[String]:
    print("=== ОТЛАДКА get_passives_for_enemy ===")
    print("enemy_name: '", enemy_name, "'")
    print("rarity: '", rarity, "'")
    print("enemy_name in enemy_passives: ", enemy_name in enemy_passives)
    print("Доступные враги в конфигурации: ", enemy_passives.keys())
    
    if enemy_name in enemy_passives:
        print("Доступные редкости для ", enemy_name, ": ", enemy_passives[enemy_name].keys())
        print("rarity in enemy_passives[enemy_name]: ", rarity in enemy_passives[enemy_name])
        if rarity in enemy_passives[enemy_name]:
            var passives = enemy_passives[enemy_name][rarity]
            print("Найденные пассивные способности: ", passives)
            return passives
        else:
            print("ОШИБКА: У врага ", enemy_name, " нет конфигурации для редкости ", rarity)
            return []
    else:
        print("ОШИБКА: Враг ", enemy_name, " не найден в конфигурации")
        print("Попробуем найти похожие имена...")
        for key in enemy_passives.keys():
            if key.to_lower().find(enemy_name.to_lower()) != -1 or enemy_name.to_lower().find(key.to_lower()) != -1:
                print("Возможно имелся в виду: ", key)
        return []
```

## Ожидаемые результаты отладки

### При следующем запуске должно быть:
```
=== ОТЛАДКА get_passives_for_enemy ===
enemy_name: 'Гоблин Воин'
rarity: 'legendary'
enemy_name in enemy_passives: true
Доступные враги в конфигурации: [список всех врагов]
Доступные редкости для Гоблин Воин: ["common", "uncommon", "rare", "epic", "legendary", "elite", "boss"]
rarity in enemy_passives[enemy_name]: true
Найденные пассивные способности: ["fighter", "restlessness", "blood_flow", "rage", "revenge"]
```

## Следующие шаги

### 1. **Проверить инициализацию пассивных способностей**
- Убедиться, что пассивные способности правильно загружаются
- Проверить, что BattleManager доступен при инициализации

### 2. **Проверить работу пассивных способностей**
- Убедиться, что пассивные способности правильно применяются к врагу
- Проверить, что они активируются в нужных условиях

### 3. **Проверить активные способности**
- Убедиться, что враг использует свои активные способности
- Проверить конфигурацию активных способностей

## Конфигурация пассивных способностей для Гоблин Воин

### Legendary редкость:
```gdscript
"legendary": ["fighter", "restlessness", "blood_flow", "rage", "revenge"]
```

### Описание способностей:
- **fighter** - базовая боевая способность
- **restlessness** - беспокойство
- **blood_flow** - кровоток
- **rage** - ярость
- **revenge** - месть

## Рекомендации

### 1. **Проверить BattleManager**
- Убедиться, что BattleManager правильно инициализируется
- Проверить, что он доступен для пассивных способностей

### 2. **Проверить порядок инициализации**
- Убедиться, что пассивные способности инициализируются после BattleManager
- Проверить, что все компоненты загружаются в правильном порядке

### 3. **Проверить логику пассивных способностей**
- Убедиться, что пассивные способности правильно срабатывают
- Проверить условия активации каждой способности

---

**Автор**: Claude AI Assistant  
**Дата**: 2024  
**Версия**: 1.0
