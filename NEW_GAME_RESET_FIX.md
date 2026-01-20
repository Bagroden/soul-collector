# Исправление сброса данных при новой игре

## 🐛 Проблема

При начале новой игры квесты и мета-прогрессия не сбрасывались, оставаясь в том же состоянии что и в предыдущей игре.

**Симптомы:**
- ✅ Квест "find_soul_urn" уже выполнен
- ✅ `met_soul_sculptor = true`
- ✅ `has_soul_urn = true`
- ✅ Валюты (души) не сбрасываются
- ❌ Игрок не может начать прохождение с нуля

---

## ✅ Решение

### 1. PlayerManager.gd - Добавлен сброс мета-прогрессии

**Файл:** `Scripts/PlayerManager.gd`  
**Функция:** `reset_player_to_default()`

**Добавлено после строки 109:**

```gdscript
# Сбрасываем мета-прогрессию и квесты
player_data.met_soul_sculptor = false
player_data.has_soul_urn = false
player_data.soul_urn_delivered = false
player_data.has_knowledge_crystal = false
player_data.has_eternity_sphere = false
player_data.max_passive_level = 0
player_data.max_soul_development_level = 0

# Очищаем квесты
player_data.active_quests.clear()
player_data.completed_quests.clear()
```

---

### 2. Currency Managers - Добавлены методы reset_data()

#### StrongSoulsManager.gd

**Файл:** `Scripts/Currency/StrongSoulsManager.gd`

**Добавлен метод:**

```gdscript
func reset_data():
	"""Сбрасывает данные сильных душ (для новой игры)"""
	strong_souls = 0
	emit_strong_souls_changed()
	# Удаляем файл сохранения
	if FileAccess.file_exists("user://strong_souls.save"):
		DirAccess.remove_absolute("user://strong_souls.save")
	print("StrongSoulsManager: Данные сброшены")
```

#### GreatSoulsManager.gd

**Файл:** `Scripts/Currency/GreatSoulsManager.gd`

**Добавлен метод:**

```gdscript
func reset_data():
	"""Сбрасывает данные великих душ (для новой игры)"""
	great_souls = 0
	emit_great_souls_changed()
	# Удаляем файл сохранения
	if FileAccess.file_exists("user://great_souls.save"):
		DirAccess.remove_absolute("user://great_souls.save")
	print("GreatSoulsManager: Данные сброшены")
```

#### DivineSoulsManager.gd

**Файл:** `Scripts/Currency/DivineSoulsManager.gd`

**Добавлен метод:**

```gdscript
func reset_data():
	"""Сбрасывает данные божественных душ (для новой игры)"""
	divine_souls = 0
	emit_divine_souls_changed()
	# Удаляем файл сохранения
	if FileAccess.file_exists("user://divine_souls.save"):
		DirAccess.remove_absolute("user://divine_souls.save")
	print("DivineSoulsManager: Данные сброшены")
```

---

### 3. MainMenu.gd - Вызов сброса валют

**Файл:** `Scripts/MainMenu.gd`  
**Функция:** `_start_new_game()`

**Добавлено перед переходом на CharacterPreparation:**

```gdscript
# Сбрасываем все валюты к начальным значениям
var soul_shard_manager = get_node_or_null("/root/SoulShard")
if soul_shard_manager:
	soul_shard_manager.reset_soul_shards()
	print("MainMenu: Осколки душ сброшены")

var strong_souls_manager = get_node_or_null("/root/StrongSouls")
if strong_souls_manager:
	strong_souls_manager.reset_data()

var great_souls_manager = get_node_or_null("/root/GreatSouls")
if great_souls_manager:
	great_souls_manager.reset_data()

var divine_souls_manager = get_node_or_null("/root/DivineSouls")
if divine_souls_manager:
	divine_souls_manager.reset_data()
```

---

## 🔄 Порядок сброса при новой игре

```
Игрок нажимает "Новая игра"
   ↓
_start_new_game()
   ↓
1. player_manager.delete_save_file()        ← Удаление user://savegame.dat
   ↓
2. player_manager.initialize_player()       ← Вызов reset_player_to_default()
   ├─> Сброс характеристик (STR, AGI, VIT...)
   ├─> Сброс ресурсов (HP, MP, Stamina)
   ├─> Сброс духовной мощи
   ├─> Очистка изученных пассивных способностей
   ├─> ✨ НОВОЕ: Сброс мета-прогрессии
   │   ├─> met_soul_sculptor = false
   │   ├─> has_soul_urn = false
   │   ├─> soul_urn_delivered = false
   │   ├─> has_knowledge_crystal = false
   │   ├─> has_eternity_sphere = false
   │   ├─> max_passive_level = 0
   │   ├─> max_soul_development_level = 0
   │   └─> Очистка active_quests и completed_quests
   └─> Пересчет бонусов
   ↓
3. ability_learning_system.reset_learning_progress()
   ↓
4. location_manager: Блокировка всех локаций кроме "dungeon"
   ↓
5. ✨ НОВОЕ: Сброс валют
   ├─> SoulShard.reset_soul_shards() → 0 осколков
   ├─> StrongSouls.reset_data() → 0 сильных душ + удаление save
   ├─> GreatSouls.reset_data() → 0 великих душ + удаление save
   └─> DivineSouls.reset_data() → 0 божественных душ + удаление save
   ↓
6. SceneTransition → CharacterPreparation
   ↓
✅ Полностью чистая новая игра!
```

---

## 📊 Что сбрасывается

### PlayerData (в reset_player_to_default):

| Категория | Что сбрасывается | Начальное значение |
|-----------|------------------|-------------------|
| **Уровень и опыт** | level, experience, gold, stat_points | 1, 0, 0, 5 |
| **Базовые характеристики** | base_strength, base_agility, base_vitality, base_endurance, base_intelligence, base_wisdom | 5, 5, 5, 5, 5, 5 |
| **Финальные характеристики** | strength, agility, vitality, endurance, intelligence, wisdom | 5, 5, 5, 5, 5, 5 |
| **Ресурсы** | current_hp, max_hp, current_mp, max_mp, current_stamina, max_stamina, base_hp, base_mp, base_stamina | 100 для всех |
| **Духовная мощь** | spiritual_power, max_spiritual_power, used_spiritual_power | 5, 5, 0 |
| **Пассивные способности** | learned_passives, active_passives | [] (пустые массивы) |
| **Бонусы от пассивных** | passive_strength_bonus, passive_agility_bonus, passive_vitality_bonus, passive_endurance_bonus, passive_intelligence_bonus, passive_wisdom_bonus, passive_hp_bonus | 0 для всех |
| **✨ Мета-прогрессия** | met_soul_sculptor, has_soul_urn, soul_urn_delivered, has_knowledge_crystal, has_eternity_sphere | false для всех |
| **✨ Лимиты прокачки** | max_passive_level, max_soul_development_level | 0 для всех |
| **✨ Квесты** | active_quests, completed_quests | [] (пустые массивы) |

### Валюты (в reset_data):

| Менеджер | Файл сохранения | Значение после сброса |
|----------|-----------------|----------------------|
| SoulShardManager | (встроено в savegame.dat) | 0 осколков |
| StrongSoulsManager | user://strong_souls.save | 0 сильных душ |
| GreatSoulsManager | user://great_souls.save | 0 великих душ |
| DivineSoulsManager | user://divine_souls.save | 0 божественных душ |

### Прочее:

| Система | Что сбрасывается |
|---------|------------------|
| AbilityLearningSystem | Весь прогресс изучения способностей врагов |
| LocationManager | Все локации заблокированы, кроме "dungeon" |
| RoomGenerator | rooms_cleared = 0 (устанавливается при старте локации) |

---

## 🎮 Результат для игрока

**ДО исправления:**
```
Новая игра
├─> Скульптор душ: "Принеси мне урну"
├─> Квест уже выполнен ❌
└─> У игрока уже есть урна ❌
```

**ПОСЛЕ исправления:**
```
Новая игра
├─> Скульптор душ: "Впервые вижу"
├─> Квест активируется при первом клике ✅
├─> Урны нет ✅
├─> Все валюты = 0 ✅
└─> Прогресс изучения способностей сброшен ✅
```

---

## 🧪 Тестирование

### Сценарий проверки:

1. **Старая игра с прогрессом:**
   - ✅ Есть урна
   - ✅ Квест выполнен
   - ✅ Много валют (души)
   - ✅ Изучены способности

2. **Нажать "Новая игра":**
   - Подтвердить в диалоге

3. **Проверить на экране подготовки:**
   - ✅ Осколков душ = 0
   - ✅ Сильных душ = 0
   - ✅ Великих душ = 0
   - ✅ Божественных душ = 0
   - ✅ Характеристики = 5 для всех
   - ✅ Очков распределения = 5
   - ✅ Уровень = 1

4. **Кликнуть на Скульптора душ:**
   - ✅ Должно появиться сообщение "Впервые вижу..." (первая встреча)
   - ✅ Квест "find_soul_urn" активируется

5. **Войти в "Подземелье под городом":**
   - ✅ Комнаты с 4-й: "Логово вора" может появиться (50%)
   - ✅ Победа над редким слизнем даст урну

6. **Вернуться и кликнуть на Скульптора:**
   - ✅ Появится опция "🏺 Доставить Урну душ"

---

## 📝 Логи для отладки

**При сбросе игрока:**
```
MainMenu: Начало новой игры - удаление сохранения и сброс данных
MainMenu: После сброса - Base STR=5 Final STR=5
Данные игрока сброшены к начальным значениям
Base stats: STR=5 AGI=5 VIT=5
Final stats: STR=5 AGI=5 VIT=5
```

**При сбросе валют:**
```
MainMenu: Осколки душ сброшены
StrongSoulsManager: Данные сброшены
GreatSoulsManager: Данные сброшены
DivineSoulsManager: Данные сброшены
```

---

## ✅ Чек-лист изменений

- [x] Добавлен сброс `met_soul_sculptor` в `PlayerManager.reset_player_to_default()`
- [x] Добавлен сброс `has_soul_urn`, `soul_urn_delivered`
- [x] Добавлен сброс `has_knowledge_crystal`, `has_eternity_sphere`
- [x] Добавлен сброс `max_passive_level`, `max_soul_development_level`
- [x] Добавлена очистка `active_quests` и `completed_quests`
- [x] Добавлен `reset_data()` в `StrongSoulsManager`
- [x] Добавлен `reset_data()` в `GreatSoulsManager`
- [x] Добавлен `reset_data()` в `DivineSoulsManager`
- [x] Обновлен `MainMenu._start_new_game()` для вызова сброса валют
- [x] Протестирован полный цикл "Новая игра"

---

**Дата исправления:** 20 ноября 2025  
**Версия:** 1.0  
**Статус:** ✅ Исправлено  
**Файлы:**
- `Scripts/PlayerManager.gd`
- `Scripts/MainMenu.gd`
- `Scripts/Currency/StrongSoulsManager.gd`
- `Scripts/Currency/GreatSoulsManager.gd`
- `Scripts/Currency/DivineSoulsManager.gd`

