# Исправление ошибок с файлами и дублированием

## ❌ Обнаруженные проблемы:

### **1. Копирование вместо перемещения файлов:**
- При изменении редкости способностей я копировал файлы вместо их перемещения
- Это привело к дублированию файлов в разных папках

### **2. Создание ненужной способности:**
- Создал `demon_power` для Executioner Demon, хотя у него уже есть все 5 способностей

### **3. Дублирующиеся файлы:**
- `Dodge.gd` - в Common и Uncommon
- `CurseWeakness.gd` - в Common и Rare  
- `ExecutionerRage.gd` - в Common и Rare
- `Agility.gd` - в Rare и Epic

## ✅ Исправления выполнены:

### **1. Удалены дублирующиеся файлы:**
- ❌ `Scripts/PassiveAbilities/Common/Dodge.gd` (должна быть только в Uncommon)
- ❌ `Scripts/PassiveAbilities/Rare/CurseWeakness.gd` (должна быть только в Common)
- ❌ `Scripts/PassiveAbilities/Rare/ExecutionerRage.gd` (должна быть только в Common)
- ❌ `Scripts/PassiveAbilities/Rare/Agility.gd` (должна быть только в Epic)

### **2. Удалена ненужная способность:**
- ❌ `Scripts/PassiveAbilities/Uncommon/DemonPower.gd` (не нужна)

### **3. Обновлены конфигурации:**
- **PassiveAbilityManager**: убрана загрузка `demon_power`
- **EnemyPassiveConfig**: убрана `demon_power` из Executioner Demon
- **AbilityLearningSystem**: убрана конфигурация изучения `demon_power`

## 📁 Правильное распределение файлов:

### **🔵 COMMON (Обычные):**
- `Scripts/PassiveAbilities/Common/ExecutionerRage.gd` ✅
- `Scripts/PassiveAbilities/Common/CurseWeakness.gd` ✅
- `Scripts/PassiveAbilities/Common/QuickStrike.gd` ✅
- `Scripts/PassiveAbilities/Common/RatBite.gd` ✅
- `Scripts/PassiveAbilities/Common/RatVitality.gd` ✅
- `Scripts/PassiveAbilities/Common/Restlessness.gd` ✅
- `Scripts/PassiveAbilities/Common/BatSpeed.gd` ✅

### **🟢 UNCOMMON (Необычные):**
- `Scripts/PassiveAbilities/Uncommon/Dodge.gd` ✅
- `Scripts/PassiveAbilities/Uncommon/DemonMage.gd` ✅
- `Scripts/PassiveAbilities/Uncommon/BloodFlow.gd` ✅
- `Scripts/PassiveAbilities/Uncommon/AlkaraVampirism.gd` ✅
- `Scripts/PassiveAbilities/Uncommon/CurseMagic.gd` ✅
- `Scripts/PassiveAbilities/Uncommon/MouseNimble.gd` ✅
- `Scripts/PassiveAbilities/Uncommon/SharpClaws.gd` ✅

### **🔵 RARE (Редкие):**
- `Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd` ✅
- `Scripts/PassiveAbilities/Rare/TharnokShield.gd` ✅
- `Scripts/PassiveAbilities/Rare/BloodSucker.gd` ✅
- `Scripts/PassiveAbilities/Rare/Infection.gd` ✅
- `Scripts/PassiveAbilities/Rare/AlkaraBloodRitual.gd` ✅
- `Scripts/PassiveAbilities/Rare/TharnokArmor.gd` ✅
- `Scripts/PassiveAbilities/Rare/NinjaAssassinate.gd` ✅
- `Scripts/PassiveAbilities/Rare/TharnokReflect.gd` ✅

### **🟣 EPIC (Эпические):**
- `Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd` ✅
- `Scripts/PassiveAbilities/Epic/Agility.gd` ✅
- `Scripts/PassiveAbilities/Epic/LifeSteal.gd` ✅
- `Scripts/PassiveAbilities/Epic/BloodBleeding.gd` ✅
- `Scripts/PassiveAbilities/Epic/NinjaShadow.gd` ✅
- `Scripts/PassiveAbilities/Epic/NinjaShadowStrike.gd` ✅
- `Scripts/PassiveAbilities/Epic/MousePack.gd` ✅
- `Scripts/PassiveAbilities/Epic/Echolocation.gd` ✅
- `Scripts/PassiveAbilities/Epic/AlkaraSoulDrain.gd` ✅
- `Scripts/PassiveAbilities/Epic/CurseCursed.gd` ✅
- `Scripts/PassiveAbilities/Epic/DemonVitality.gd` ✅
- `Scripts/PassiveAbilities/Epic/NinjaLethality.gd` ✅

## 🎮 Правильная прогрессия Executioner Demon:

### **Common** → `executioner_rage` (Ярость палача)
- **Механика**: Урон увеличивается на 50% при низком HP владельца (меньше 20%)
- **Стоимость**: 100 осколков душ

### **Uncommon** → `executioner_rage` (только базовая способность)
- **Примечание**: На этом уровне нет дополнительных способностей

### **Rare** → `executioner_rage` + `executioner_judgment` (Суд палача)
- **Механика**: 30% шанс наложить метку суда, которая взрывается через 2 хода
- **Стоимость**: 500 осколков душ

### **Epic** → `executioner_rage` + `executioner_guillotine` (Гильотина палача) + `executioner_judgment`
- **Механика**: Увеличивает критический урон в 3 раза
- **Стоимость**: 700 осколков душ

### **Legendary** → `executioner_rage` + `executioner_guillotine` + `executioner_judgment` + `executioner_final` (Последний приговор)
- **Механика**: При получении смертельного урона не умирает, HP снижается до 1 и проводит контратаку с усилением в 300%
- **Стоимость**: 1000 осколков душ

## 🔧 Обновленные конфигурации:

### **PassiveAbilityManager.gd:**
```gdscript
# _load_common_abilities():
var executioner_rage = load("res://Scripts/PassiveAbilities/Common/ExecutionerRage.gd").new()
abilities["executioner_rage"] = executioner_rage

# _load_uncommon_abilities():
var demon_mage = load("res://Scripts/PassiveAbilities/Uncommon/DemonMage.gd").new()
abilities["demon_mage"] = demon_mage

# _load_rare_abilities():
var executioner_judgment = load("res://Scripts/PassiveAbilities/Rare/ExecutionerJudgment.gd").new()
abilities["executioner_judgment"] = executioner_judgment

# _load_epic_abilities():
var executioner_guillotine = load("res://Scripts/PassiveAbilities/Epic/ExecutionerGuillotine.gd").new()
abilities["executioner_guillotine"] = executioner_guillotine
```

### **EnemyPassiveConfig.gd:**
```gdscript
"ExecutionerDemon": {
    "common": ["executioner_rage"],
    "uncommon": ["executioner_rage"],
    "rare": ["executioner_rage", "executioner_judgment"],
    "epic": ["executioner_rage", "executioner_guillotine", "executioner_judgment"],
    "legendary": ["executioner_rage", "executioner_guillotine", "executioner_judgment", "executioner_final"]
}
```

## ⚠️ Урок на будущее:

### **Правильные операции с файлами:**
1. **Перемещение**: `move` команда для изменения расположения файлов
2. **НЕ копирование**: избегать создания дублирующихся файлов
3. **Проверка**: всегда проверять, что файлы находятся в правильных папках
4. **Очистка**: удалять ненужные файлы сразу после создания

### **Правильная работа с конфигурациями:**
1. **Проверка**: убедиться, что у врага действительно нужна новая способность
2. **Счет**: Executioner Demon уже имеет 5 способностей (rage, judgment, guillotine, final + базовая)
3. **Логика**: не создавать способности без необходимости

## ✅ Статус: Исправлено

Все дублирующиеся файлы удалены, ненужная способность убрана, конфигурации исправлены!
