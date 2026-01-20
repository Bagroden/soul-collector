# Руководство по добавлению эффектов к анимациям способностей врагов

## 📋 Обзор системы

Система эффектов позволяет проигрывать визуальные эффекты на цели атаки (игроке) во время использования способности врагом. Эффект проигрывается поверх анимации `hurt` на отдельном узле `EffectVisual`, что позволяет визуальным эффектам не конфликтовать с основными анимациями персонажа.

### Основные компоненты:

1. **Узел `EffectVisual`** - отдельный `AnimatedSprite2D` на игроке для проигрывания эффектов
2. **`AbilityAnimations.tres`** - ресурс с маппингом ID способностей на имена анимаций
3. **`battle_manager.gd`** - логика проигрывания эффектов в момент удара
4. **`SpriteFrames` игрока** - содержит анимации эффектов

---

## 🎯 Когда использовать эффекты

Эффекты используются для способностей, которые должны визуально отображаться на цели атаки:
- **Крысиный укус** (`rat_bite`) - эффект когтей/укуса
- **Пикирование** (`bat_swoop`) - эффект пикирования
- **Кислотный взрыв** (`acid_blast`) - эффект кислоты
- **Ядовитый удар** (`poison_strike`) - эффект яда
- **Двойной удар** (`double_strike`) - эффект удара мечом
- И другие способности, требующие визуального эффекта на цели

---

## 📁 Структура файлов

```
Scripts/Battle/
├── battle_manager.gd          # Логика проигрывания эффектов
├── character_visual.gd         # Управление анимациями
└── AbilityAnimationData.gd     # Ресурс для хранения маппинга

Data/
└── AbilityAnimations.tres     # Файл с маппингом способностей

Scenes/Battle/
└── PlayerBody.tscn             # Сцена игрока с узлом EffectVisual
```

---

## 🔧 Пошаговая инструкция

### Шаг 1: Добавление анимации эффекта в SpriteFrames игрока

1. Откройте `Scenes/Battle/PlayerBody.tscn` в Godot
2. Выберите узел `Visual` или `EffectVisual`
3. В инспекторе откройте `Sprite Frames`
4. Добавьте новую анимацию с именем `{ability_id}_anim` (например, `rat_bite_anim`)
5. Назначьте спрайты эффекта (текстуры для анимации)
6. Настройте параметры анимации:
   - `Speed` - скорость проигрывания (обычно 8.0)
   - `Loop` - должен быть `false` (анимация не зациклена)

**Пример:**
- Для `rat_bite` → анимация `rat_bite_anim`
- Для `acid_blast` → анимация `acid_blast_anim`
- Для `poison_strike` → анимация `poison_strike_anim`

---

### Шаг 2: Добавление записи в AbilityAnimations.tres

1. Откройте `Data/AbilityAnimations.tres` в текстовом редакторе или в Godot
2. Добавьте новую запись в словарь `ability_animations`:

```tres
ability_animations = {
"rat_bite": "rat_bite_anim",
"bat_swoop": "bat_swoop_anim",
"acid_blast": "acid_blast_anim",
"poison_strike": "poison_strike_anim",
"double_strike": "double_strike_anim",
"crossbow_shot": "crossbow_shot_anim",
"slashing_strike": "slashing_strike_anim",
"rending_claws": "rending_claws_anim",
"ваша_способность": "ваша_анимация_эффекта"
}
```

**Формат:** `"ability_id": "animation_name"`

---

### Шаг 3: Добавление логики в battle_manager.gd

Найдите блок обработки способности в функции `_enemy_action()` и добавьте код эффекта.

#### Для одноударных способностей:

```gdscript
elif result.get("ваша_способность", false):
    # Враг проигрывает стандартную атаку (уже проиграна в общем блоке)
    # Ждем момента удара в анимации атаки (примерно середина анимации)
    await get_tree().create_timer(0.35).timeout
    
    # На игроке проигрываем анимацию эффекта на отдельном узле эффектов
    var player_effect_visual = player_node.get_node_or_null("EffectVisual")
    if player_effect_visual:
        # Копируем sprite_frames из основного Visual, если они не установлены
        if player_effect_visual.sprite_frames == null:
            var player_visual = player_node.get_node_or_null("Visual")
            if player_visual and player_visual.sprite_frames != null:
                player_effect_visual.sprite_frames = player_visual.sprite_frames
        
        if player_effect_visual.sprite_frames != null and player_effect_visual.sprite_frames.has_animation("ваша_анимация_эффекта"):
            print("DEBUG: Проигрываем анимацию эффекта 'ваша_анимация_эффекта' на игроке (поверх hurt)")
            # Показываем узел эффектов
            player_effect_visual.visible = true
            # Проигрываем анимацию эффекта
            if player_effect_visual.has_method("play_animation"):
                player_effect_visual.play_animation("ваша_анимация_эффекта")
                # Ждем завершения анимации и скрываем узел
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
            else:
                # Fallback: используем прямой вызов
                player_effect_visual.play("ваша_анимация_эффекта")
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
        else:
            print("DEBUG: Анимация 'ваша_анимация_эффекта' не найдена в SpriteFrames игрока")
    else:
        print("DEBUG: Узел EffectVisual не найден на игроке")
    
    # Наносим урон (код обработки урона)
    var player_old_hp = player_node.hp
    player_node.take_damage(damage, damage_type)
    var actual_damage = player_old_hp - player_node.hp
    DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
```

#### Для многоударных способностей (например, double_strike):

```gdscript
# Первый удар
if _calculate_hit_chance(enemy_node, player_node, "double_strike_1", "Двойной удар (1-й удар)"):
    # Ждем момента удара в анимации атаки
    await get_tree().create_timer(0.35).timeout
    
    # Звук первого удара
    if SoundManager:
        SoundManager.play_sound("sword_attack1", -5.0)
    
    # Эффект на игроке (асинхронно, не ждем завершения)
    var player_effect_visual = player_node.get_node_or_null("EffectVisual")
    if player_effect_visual:
        if player_effect_visual.sprite_frames == null:
            var player_visual = player_node.get_node_or_null("Visual")
            if player_visual and player_visual.sprite_frames != null:
                player_effect_visual.sprite_frames = player_visual.sprite_frames
        
        if player_effect_visual.sprite_frames != null and player_effect_visual.sprite_frames.has_animation("double_strike_anim"):
            player_effect_visual.visible = true
            if player_effect_visual.has_method("play_animation"):
                player_effect_visual.play_animation("double_strike_anim")
                player_effect_visual.animation_finished.connect(func(): player_effect_visual.visible = false, CONNECT_ONE_SHOT)
            else:
                player_effect_visual.play("double_strike_anim")
                player_effect_visual.animation_finished.connect(func(): player_effect_visual.visible = false, CONNECT_ONE_SHOT)
    
    # Наносим урон и показываем цифру
    var player_old_hp = player_node.hp
    player_node.take_damage(first_hit_damage, damage_type)
    var actual_first_damage = player_old_hp - player_node.hp
    DamageNumberManager.show_damage_on_character(player_node, actual_first_damage, first_hit_crit, false, false, damage_type)
```

**Важно для многоударных способностей:**
- Используйте `animation_finished.connect()` с `CONNECT_ONE_SHOT` вместо `await`
- Это позволяет эффекту проигрываться асинхронно, не блокируя выполнение кода

---

### Шаг 4: Проверка синхронизации

Убедитесь, что эффект синхронизирован с анимацией атаки врага:

1. **Задержка перед эффектом:** `await get_tree().create_timer(0.35).timeout`
   - Это задержка до момента удара в анимации атаки
   - Может потребоваться корректировка в зависимости от длительности анимации атаки

2. **Порядок событий:**
   - Враг начинает анимацию атаки
   - Ждем 0.35 секунды (момент удара)
   - Одновременно: звук, эффект на игроке, урон, цифра урона

---

## 📝 Примеры реализации

### Пример 1: Крысиный укус (rat_bite)

```gdscript
elif result.get("rat_bite", false):
    # Крыса проигрывает стандартную атаку (уже проиграна в общем блоке)
    # На игроке проигрываем анимацию эффекта когтей/укуса на отдельном узле эффектов
    var player_effect_visual = player_node.get_node_or_null("EffectVisual")
    if player_effect_visual:
        if player_effect_visual.sprite_frames == null:
            var player_visual = player_node.get_node_or_null("Visual")
            if player_visual and player_visual.sprite_frames != null:
                player_effect_visual.sprite_frames = player_visual.sprite_frames
        
        if player_effect_visual.sprite_frames != null and player_effect_visual.sprite_frames.has_animation("rat_bite_anim"):
            print("DEBUG: Проигрываем анимацию эффекта 'rat_bite_anim' на игроке (поверх hurt)")
            # Задержка для синхронизации с моментом удара
            await get_tree().create_timer(0.35).timeout
            # Показываем узел эффектов
            player_effect_visual.visible = true
            # Проигрываем анимацию эффекта
            if player_effect_visual.has_method("play_animation"):
                player_effect_visual.play_animation("rat_bite_anim")
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
            else:
                player_effect_visual.play("rat_bite_anim")
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
```

### Пример 2: Кислотный взрыв (acid_blast)

```gdscript
elif result.get("acid_blast", false):
    # Слизень проигрывает стандартную атаку (уже проиграна в общем блоке)
    # Проигрываем звук кислотного взрыва
    if SoundManager:
        SoundManager.play_sound("acid_blast", -5.0)
    
    # Ждем момента удара в анимации атаки
    await get_tree().create_timer(0.35).timeout
    
    # На игроке проигрываем анимацию эффекта кислотного взрыва
    var player_effect_visual = player_node.get_node_or_null("EffectVisual")
    if player_effect_visual:
        if player_effect_visual.sprite_frames == null:
            var player_visual = player_node.get_node_or_null("Visual")
            if player_visual and player_visual.sprite_frames != null:
                player_effect_visual.sprite_frames = player_visual.sprite_frames
        
        if player_effect_visual.sprite_frames != null and player_effect_visual.sprite_frames.has_animation("acid_blast_anim"):
            player_effect_visual.visible = true
            if player_effect_visual.has_method("play_animation"):
                player_effect_visual.play_animation("acid_blast_anim")
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
            else:
                player_effect_visual.play("acid_blast_anim")
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
    
    # Наносим урон
    var player_old_hp = player_node.hp
    player_node.take_damage(damage, damage_type)
    var actual_damage = player_old_hp - player_node.hp
    DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
```

---

## ⚠️ Частые проблемы и решения

### Проблема 1: Эффект не проигрывается

**Причины:**
- Анимация не добавлена в `SpriteFrames` игрока
- Неправильное имя анимации в `AbilityAnimations.tres`
- Узел `EffectVisual` не найден

**Решение:**
- Проверьте, что анимация добавлена в `PlayerBody.tscn` → `Visual` или `EffectVisual` → `Sprite Frames`
- Убедитесь, что имя в `AbilityAnimations.tres` совпадает с именем анимации
- Проверьте логи в консоли на наличие ошибок

---

### Проблема 2: Эффект проигрывается до анимации атаки

**Причина:**
- Отсутствует задержка `await get_tree().create_timer(0.35).timeout`

**Решение:**
- Добавьте задержку перед проигрыванием эффекта
- Может потребоваться корректировка времени (0.3-0.4 секунды) в зависимости от анимации

---

### Проблема 3: Эффект дублируется или накладывается

**Причина:**
- Узел `EffectVisual` не скрывается после завершения анимации
- Анимация зациклена (`Loop = true`)

**Решение:**
- Убедитесь, что после `await player_effect_visual.animation_finished` есть `player_effect_visual.visible = false`
- Проверьте, что анимация не зациклена в `SpriteFrames`

---

### Проблема 4: Эффект не синхронизирован с уроном

**Причина:**
- Урон наносится до проигрывания эффекта
- Неправильный порядок вызовов

**Решение:**
- Убедитесь, что урон наносится ПОСЛЕ задержки и проигрывания эффекта
- Для многоударных способностей используйте асинхронное проигрывание эффекта

---

## 🔍 Отладка

### Включение отладочных сообщений

В коде уже есть отладочные `print()` сообщения. Они помогут понять, что происходит:

```
DEBUG: Проигрываем анимацию эффекта 'rat_bite_anim' на игроке (поверх hurt)
DEBUG: Анимация 'rat_bite_anim' не найдена в SpriteFrames игрока
DEBUG: Узел EffectVisual не найден на игроке
```

### Проверка наличия анимации

В консоли Godot можно проверить доступные анимации:
```gdscript
print("Доступные анимации: ", player_effect_visual.sprite_frames.get_animation_names())
```

---

## ✅ Чеклист добавления эффекта

- [ ] Анимация эффекта добавлена в `SpriteFrames` игрока (`PlayerBody.tscn`)
- [ ] Имя анимации соответствует формату `{ability_id}_anim`
- [ ] Анимация не зациклена (`Loop = false`)
- [ ] Запись добавлена в `Data/AbilityAnimations.tres`
- [ ] Логика эффекта добавлена в `battle_manager.gd` в блок обработки способности
- [ ] Задержка синхронизации добавлена (`await get_tree().create_timer(0.35).timeout`)
- [ ] Узел `EffectVisual` скрывается после завершения анимации
- [ ] Урон наносится после проигрывания эффекта
- [ ] Протестировано в игре

---

## 📚 Дополнительные ресурсы

- **Система анимаций способностей:** `ABILITY_ANIMATION_SYSTEM.md`
- **Файл маппинга:** `Data/AbilityAnimations.tres`
- **Логика боя:** `Scripts/Battle/battle_manager.gd`
- **Управление анимациями:** `Scripts/Battle/character_visual.gd`

---

## 💡 Советы

1. **Именование:** Используйте единообразные имена: `{ability_id}_anim`
2. **Синхронизация:** Задержка 0.35 секунды обычно работает хорошо, но может потребоваться корректировка
3. **Многоударные способности:** Используйте асинхронное проигрывание эффекта для каждого удара
4. **Тестирование:** Всегда тестируйте эффект в игре после добавления
5. **Оптимизация:** Эффекты должны быть короткими (1-2 секунды), чтобы не замедлять бой

---

**Последнее обновление:** 2024
**Версия:** 1.0

