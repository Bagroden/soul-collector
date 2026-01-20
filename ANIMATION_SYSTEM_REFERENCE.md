# Справочник по системе анимаций способностей врагов

## 📋 Обзор системы

Система позволяет проигрывать визуальные эффекты способностей врагов на теле игрока через специальный узел `EffectVisual`.

---

## 🏗️ Архитектура

### Компоненты:

1. **EnemyAbility.gd** - Определяет способность и возвращает флаг
2. **battle_manager.gd** - Обрабатывает флаг и запускает анимацию
3. **PlayerBody.tscn** - Содержит узел `EffectVisual` с анимациями
4. **SpriteFrames** - Хранит все анимации эффектов

---

## 📝 Как добавить новую анимацию

### Шаг 1: Добавьте флаг в способность

В `Scripts/Abilities/EnemyAbility.gd`:

```gdscript
return {
    "success": true,
    "damage": your_damage,
    "is_crit": your_crit,
    "damage_type": damage_type,
    "message": owner.display_name + " использует " + name + "!",
    "your_ability_flag": true  # ← Ваш уникальный флаг
}
```

### Шаг 2: Обработайте флаг в battle_manager

В `Scripts/Battle/battle_manager.gd`, в функции `_enemy_action()`:

```gdscript
elif result.get("your_ability_flag", false):
    # Проигрываем звук
    if SoundManager:
        SoundManager.play_sound("sound_name", -5.0)
    
    # Ждем момента удара
    await get_tree().create_timer(0.35).timeout
    
    # Запускаем анимацию на игроке
    var player_effect_visual = player_node.get_node_or_null("EffectVisual")
    if player_effect_visual:
        # Копируем sprite_frames если нужно
        if player_effect_visual.sprite_frames == null:
            var player_visual = player_node.get_node_or_null("Visual")
            if player_visual and player_visual.sprite_frames != null:
                player_effect_visual.sprite_frames = player_visual.sprite_frames
        
        # Проигрываем анимацию
        if player_effect_visual.sprite_frames != null and player_effect_visual.sprite_frames.has_animation("your_anim_name"):
            player_effect_visual.visible = true
            if player_effect_visual.has_method("play_animation"):
                player_effect_visual.play_animation("your_anim_name")
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
            else:
                player_effect_visual.play("your_anim_name")
                await player_effect_visual.animation_finished
                player_effect_visual.visible = false
    
    # Наносим урон
    var player_old_hp = player_node.hp
    player_node.take_damage(damage, damage_type)
    var actual_damage = player_old_hp - player_node.hp
    DamageNumberManager.show_damage_on_character(player_node, actual_damage, is_crit, false, false, damage_type)
    
    # Тряска камеры
    if is_crit and camera and camera.has_method("shake"):
        camera.shake(0.3, 15.0)
    
    # Триггерим пассивки
    var context_attack = {"damage": damage, "target": player_node, "ability_used": true, "is_critical": is_crit, "damage_type": damage_type}
    enemy_node.trigger_passive_abilities(PassiveAbilityClass.TriggerType.ON_ATTACK, player_node, context_attack)
```

### Шаг 3: Добавьте анимацию в PlayerBody

1. Откройте `Scenes/Battle/PlayerBody.tscn`
2. Выберите узел `EffectVisual`
3. В Inspector → `Sprite Frames` → **Edit**
4. Добавьте новую анимацию с именем `your_anim_name`
5. Добавьте кадры из спрайтшита
6. Настройте скорость и отключите loop
7. Сохраните

---

## 📊 Существующие анимации

### 1. acid_blast_anim
- **Владелец:** Слизень
- **Эффект:** Зеленые брызги кислоты
- **Кадров:** 7
- **Speed:** 8 FPS
- **Цвет:** Зеленый

### 2. shadow_spikes_anim
- **Владелец:** Тёмный шатун
- **Эффект:** Теневые шипы
- **Кадров:** 6-8
- **Speed:** 10 FPS
- **Цвет:** Темно-фиолетовый/синий

### 3. spiritual_strike_anim
- **Владелец:** Игрок
- **Эффект:** Духовный удар
- **Используется:** Для способности игрока

---

## 🎨 Рекомендации по дизайну

### Размер кадров:
- **Стандарт:** 128x58 пикселей
- **Масштаб в игре:** x2 (256x116 на экране)

### Количество кадров:
- **Минимум:** 4-5 кадров
- **Оптимально:** 6-8 кадров
- **Максимум:** 10-12 кадров

### Скорость:
- **Быстрая атака:** 12-15 FPS
- **Средняя атака:** 8-10 FPS
- **Медленная атака:** 6-8 FPS

### Цветовая палитра:
- **Физическ ие атаки:** Красный, оранжевый
- **Магические атаки:** Синий, фиолетовый, голубой
- **Кислота/Яд:** Зеленый, желто-зеленый
- **Теневые атаки:** Темно-фиолетовый, черный, синий
- **Огонь:** Оранжевый, желтый, красный
- **Лед:** Голубой, белый, светло-синий

---

## ⚙️ Настройки EffectVisual

### Базовые параметры:
```gdscript
[node name="EffectVisual" type="AnimatedSprite2D" parent="."]
visible = false           # По умолчанию скрыт
z_index = 1              # Отображается поверх персонажа
scale = Vector2(2, 2)    # Масштаб x2
position = Vector2(0, 0) # Позиция (можно настроить)
```

### Настройка позиции:
- **Центр:** `Vector2(0, 0)`
- **Выше:** `Vector2(0, -20)`
- **Ниже:** `Vector2(0, 20)`
- **Левее:** `Vector2(-20, 0)`
- **Правее:** `Vector2(20, 0)`

### Настройка масштаба:
- **Маленький:** `Vector2(1.5, 1.5)`
- **Стандарт:** `Vector2(2, 2)`
- **Большой:** `Vector2(2.5, 2.5)`
- **Огромный:** `Vector2(3, 3)`

---

## 🔧 Troubleshooting

### Проблема: Анимация не проигрывается

**Решение:**
1. Проверьте имя анимации (должно совпадать!)
2. Убедитесь что анимация добавлена в SpriteFrames
3. Проверьте консоль на ошибки

### Проблема: Анимация в неправильном месте

**Решение:**
1. Измените `position` узла `EffectVisual`
2. Добавьте `offset` в инспекторе
3. Проверьте `scale` (возможно слишком большой)

### Проблема: Анимация слишком быстрая/медленная

**Решение:**
1. Измените `Speed (FPS)` в SpriteFrames
2. Увеличьте задержку в `battle_manager.gd`: `create_timer(0.5)`

### Проблема: Анимация не скрывается после окончания

**Решение:**
1. Убедитесь что `loop = false` в SpriteFrames
2. Проверьте что есть `player_effect_visual.visible = false`
3. Убедитесь что `await animation_finished` присутствует

---

## 📚 Примеры кода

### Простая анимация без урона:

```gdscript
elif result.get("buff_effect", false):
    var player_effect_visual = player_node.get_node_or_null("EffectVisual")
    if player_effect_visual and player_effect_visual.sprite_frames:
        if player_effect_visual.sprite_frames.has_animation("buff_anim"):
            player_effect_visual.visible = true
            player_effect_visual.play("buff_anim")
            await player_effect_visual.animation_finished
            player_effect_visual.visible = false
```

### Анимация с множественными эффектами:

```gdscript
elif result.get("combo_attack", false):
    # Первая анимация
    player_effect_visual.play("hit_anim_1")
    await player_effect_visual.animation_finished
    
    # Урон
    player_node.take_damage(first_damage, damage_type)
    
    # Вторая анимация
    player_effect_visual.play("hit_anim_2")
    await player_effect_visual.animation_finished
    
    # Второй урон
    player_node.take_damage(second_damage, damage_type)
    
    player_effect_visual.visible = false
```

### Анимация с условным эффектом:

```gdscript
elif result.get("poison_attack", false):
    # Основная анимация
    player_effect_visual.play("poison_anim")
    await player_effect_visual.animation_finished
    
    # Урон
    player_node.take_damage(damage, damage_type)
    
    # Условный эффект (если яд наложен)
    if result.get("poison_applied", false):
        _show_message("ОТРАВЛЕН! -5 ОЗ в ход!", 2.0)
        player_node.add_effect("poison", 3.0, 3, {"damage": 5})
    
    player_effect_visual.visible = false
```

---

## 🎯 Checklist для новой анимации

- [ ] Спрайтшит подготовлен (PNG, прозрачность, 6-8 кадров)
- [ ] Спрайтшит импортирован в Assets
- [ ] Флаг добавлен в EnemyAbility.gd
- [ ] Обработка добавлена в battle_manager.gd
- [ ] Анимация создана в PlayerBody.tscn → EffectVisual
- [ ] Все кадры добавлены в анимацию
- [ ] Скорость настроена
- [ ] Loop отключен
- [ ] Протестировано в игре
- [ ] Синхронизация урона проверена
- [ ] Звуковые эффекты добавлены

---

**Автор:** Claude AI Assistant  
**Дата:** 2024  
**Версия:** 1.0

