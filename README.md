# Swift Market

## Как запустить

1. Открыть проект `swift_market.xcodeproj` в Xcode.
2. Выбрать симулятор iPhone.
3. Запустить `Run`.

Если Xcode показывает `Multiple commands produce ... Info.plist`, нужно удалить [`Info.plist`](/Users/daniil/Desktop/swift_market/swift_market/Info.plist) из `Target -> Build Phases -> Copy Bundle Resources` и оставить его только в `Build Settings -> Info.plist File`.

## Верные данные для входа

- `email`: `demo@swiftmarket.app`
- `password`: `swift123`

Проверка локальная, сеть не используется.

## Что происходит после успешного входа

После успешной авторизации приложение переходит на экран-заглушку `Список фич`, который показывает greeting, список категорий и список доступных элементов каталога. Это соответствует требованиям лабораторной: после логина открывается следующий экран приложения.

## Реализация лабораторной

- `UIKit`-экран авторизации собран вручную через `Auto Layout`.
- Используется архитектура `MVP + Coordinator`.
- `ViewController` не хранит бизнес-логику входа.
- Зависимости выражены через протоколы `AuthView`, `AuthPresenterProtocol`, `AuthRouter`, `AuthService`.
- Навигация выполняется через [`AppCoordinator`](/Users/daniil/Desktop/swift_market/swift_market/Application/AppCoordinator.swift).
- Для маленьких экранов экран авторизации обёрнут в `UIScrollView`.
- Клавиатура учитывается через обновление `contentInset`, поэтому поля и кнопка не перекрываются.
- При неверных данных показывается inline-ошибка.
- Во время проверки кнопка входа дизейблится и отображается индикатор загрузки.
- `Return` на клавиатуре переводит фокус `email -> password -> submit`.

## Структура

- `Application/` содержит координатор приложения.
- `Modules/Auth/` содержит полностью реализованный экран авторизации.
- `Modules/Catalog/` содержит экран-заглушку после успешного входа.
- `Modules/ProductDetails/` содержит каркас карточки товара.
- `Shared/` содержит доменные модели, контракты и stub-реализации.
