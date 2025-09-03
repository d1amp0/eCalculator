# 📊 eCalculator

**eCalculator** — мобильное приложение на Flutter для работы с электронным дневником **eSchool**. Оно помогает быстро считать средний балл и удобно работать с домашними заданиями.

> ⚠️ Примечание: проект не связан с eSchool официально.

---

## ✨ Возможности

* 📈 **Калькулятор среднего балла** по предметам на основе оценок из eSchool.
* 📝 **Домашние задания**: просмотр всех домашних из дневника + возможность **создавать свои**.
* 🔎 Поиск/фильтрация по предметам и датам (если реализовано в UI).
* 💾 Локальное сохранение данных (SQLite/SharedPreferences).
* 🌐 Локализация интерфейса (intl + flutter\_localizations).

---

## 🚀 Быстрый старт

### Требования

* Flutter **>= 3.5.3** (см. `environment.sdk` в `pubspec.yaml`).
* Dart SDK, Android Studio/Xcode по необходимости.

### Установка

1. Клонируйте проект:

```bash
git clone https://github.com/username/eCalculator.git
cd eCalculator
```

2. Установите зависимости:

```bash
flutter pub get
```

3. Запустите приложение на подключённом устройстве/эмуляторе:

```bash
flutter run
```

> Если в `pubspec.yaml` сейчас имя пакета `hello`, переименуйте на `ecalculator` (или желаемое) перед публикацией.

---

## 🧩 Зависимости (из `pubspec.yaml`)

* **state management:** `provider`
* **UI/UX:** `popover`, `cupertino_icons`
* **хранение:** `shared_preferences`, `sqflite`, `path_provider`, `path`, `sqlite3_flutter_libs`, `sqflite_common_ffi` (для desktop)
* **сеть и парсинг:** `http`, `crypto`, `convert`, `charset_converter`
* **контент:** `flutter_widget_from_html`
* **локализация/форматирование:** `flutter_localizations`, `intl`
* **deeplinks/URL:** `url_launcher`

Полный список и версии смотрите в `pubspec.yaml`.

---

## 🗂️ Структура проекта (рекомендация)

```
lib/
 ├─ images/              # ассеты (подключены в pubspec)
 ├─ pages/               # страницы
 ├─ other/               # разные функции
 ├─ server/              # серверные запросы
 ├─ components/          # переиспользуемые UI-компоненты
 └─ main.dart            # точка входа
```

---

## 📦 Сборка

### Android

```bash
flutter build apk --release
```

Подпись и загрузка — через Play Console.

### iOS

```bash
flutter build ios --release
```

Откройте проект в Xcode для настройки подписи и загрузки в App Store Connect.

### Web (опционально)

```bash
flutter build web
```

Готовую папку `build/web` можно деплоить на любой хостинг статики.

### Desktop (опционально)

С учётом `sqflite_common_ffi` проект можно адаптировать под desktop. Проверьте инициализацию FFI для вашей ОС и поддержку нужных плагинов.

---

## 🔐 Конфигурация и данные

* Убедитесь, что соблюдаете политику и условия использования eSchool.
* Конфиденциальные данные (логины/пароли) **не** храните в репозитории.

---

## 🐞 Отладка

* Проверяйте логи:

```bash
flutter run -v
```

* Обновите зависимости:

```bash
flutter pub upgrade --major-versions
```

* Проверка устаревших пакетов:

```bash
flutter pub outdated
```

---

## 🤝 Вклад в проект

PR-ы и Issues приветствуются. Пожалуйста, описывайте проблему и шаги для воспроизведения.

---

## 📄 Лицензия

MIT — используйте свободно, ответственность на пользователе.
