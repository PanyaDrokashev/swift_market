# Swift Market

## Архитектура

Для лабораторной выбрана архитектура `MVP + Coordinator`.

- `ViewController` отвечает только за отображение состояния и отправку событий пользователя.
- `Presenter` содержит сценарии экрана и легко тестируется через моки `View`, `Router` и `Service`.
- `Coordinator` выносит навигацию из экранов и делает переходы между модулями явными.
- Сервисы и репозитории разделяют `Presentation`, `Domain` и `Data`, поэтому зависимости можно подменять на заглушки.
- Для каталога данные идут по цепочке `NetworkClient -> CatalogRepository -> CatalogService -> CatalogPresenter`, DTO не попадают во view слой.
- Список товаров реализован через `UITableView` + `CatalogProductsListManager`, поэтому `UIViewController` не содержит datasource/delegate и логику reuse.


## Модули

- `Auth`: авторизация пользователя и получение `UserSession`.
- `Catalog`: список категорий и товаров, вход в основной сценарий маркета.
- `ProductDetails`: карточка одного товара со статусом наличия и доставкой.

## Экраны

### 1. Auth

Вход:

- `AuthModuleInput(prefilledEmail:)` для автозаполнения email.

Выход:

- `authModuleDidAuthenticate(_:)` после успешного входа.

Состояния UI:

- `initial`
- `loading`
- `content`
- `error`

Основные сценарии:

- Пользователь открывает экран, презентер отправляет `initial` с подготовленным `AuthInitialViewModel`.
- Пользователь вводит email и пароль, нажимает login, экран переходит в `loading`.
- `AuthService` возвращает `UserSession`, роутер открывает каталог.
- Если авторизация не удалась, экран получает состояние `error` с текстом ошибки.

### 2. Catalog

Вход:

- `CatalogModuleInput(session:selectedCategoryID:)` с активной сессией и выбранной категорией.

Выход:

- `catalogModuleDidSelectProduct(_:)` при выборе товара.
- `catalogModuleDidRequestLogout()` при выходе.

Состояния UI:

- `idle`
- `loading`
- `content`
- `empty`
- `error`

Основные сценарии:

- После открытия экран отдает `idle`, затем асинхронно запрашивает каталог и показывает `loading`.
- При успешной загрузке отображается `content` со списком категорий и `UITableView`-списком товаров.
- При выборе категории запускается повторная загрузка каталога с новым фильтром.
- Если пользователь запускает повторную загрузку, предыдущий `Task` отменяется.
- При выборе товара роутер открывает детальный экран.
- При ошибке без контента показывается `error` + кнопка повтора, при пустом списке показывается `empty`.

### 3. ProductDetails

Вход:

- `ProductDetailsModuleInput(productID:source:)` с идентификатором товара и источником перехода.

Выход:

- `productDetailsModuleDidFinish()` при закрытии экрана.

Состояния UI:

- `initial`
- `loading`
- `content`
- `error`

Основные сценарии:

- Экран открывается по `productID` и сразу запрашивает детали товара.
- Во время загрузки пользователь видит `loading`.
- После ответа сервиса экран показывает `content` с ценой, атрибутами, наличием и доставкой.
- Если загрузка не удалась, экран получает `error`.

## Ключевые протоколы

### View ↔ Presentation

- `AuthView`, `AuthPresenterProtocol`
- `CatalogView`, `CatalogPresenterProtocol`
- `ProductDetailsView`, `ProductDetailsPresenterProtocol`

### Presentation ↔ Domain

- `AuthService`
- `CatalogService`
- `ProductDetailsService`

### Domain ↔ Data

- `AuthRepository`
- `CatalogRepository`
- `ProductRepository`
- `SessionStorage`

### Router / Navigation

- `AuthRouter`
- `CatalogRouter`
- `ProductDetailsRouter`
- `AppCoordinator`

## Ключевые модели

- `LoginRequest`
- `UserSession`
- `Money`
- `ProductCategory`
- `ProductListItem`
- `CatalogResponseDTO`
- `ProductDetails`
- `ProductAttribute`
- `DeliveryInfo`
- `MarketError`
- `AuthViewState`
- `CatalogViewState`
- `ProductDetailsViewState`

## Структура проекта

- `Application/` содержит `AppCoordinator`.
- `Modules/Auth/` содержит контракты и пустую сборку экрана авторизации.
- `Modules/Catalog/` содержит контракты и пустую сборку каталога.
- `Modules/ProductDetails/` содержит контракты и пустую сборку карточки товара.
- `Shared/` содержит доменные модели, DTO, сетевой клиент, data-контракты, fallback JSON и реализации сервисов.
