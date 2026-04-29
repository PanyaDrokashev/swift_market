## Лабораторная 7

Сделана структура BDUI. Основная сущность — Shared/BDUI/BDUIMapper для маппинга JSON в дерево BDUINode (элемент BDUI)

Доп. таска — реализованы экшены (релоад, принт (заглушка) и роутинг)

Роутнг реализован через чтение эндпоинта в экшене (напр. swift-market/product). Далее этот энподинт передается в сервис, где идет запрос на запрошенный JSON 

## Лабораторная 8

Добавлен универсальный экран на DBUI, который использует маппер из ЛР7.

Для каждого экрана передается свой `key` (`swift-market/auth`, `swift-market/catalog`, `swift-market/product`)

Пример JSON:

```json
{
    "type": "view",
    "style": {
        "backgroundColor": "background"
    },
    "layout": {
        "contentInsets": {
            "top": 16,
            "left": 16,
            "right": 16,
            "bottom": 24
        }
    },
    "subviews": [
        {
            "type": "stack",
            "layout": {
                "axis": "vertical",
                "spacing": "s"
            },
            "subviews": [
                {
                    "type": "label",
                    "style": {
                        "font": "title",
                        "textColor": "textPrimary",
                        "numberOfLines": 0
                    },
                    "content": {
                        "text": "Каталог товаров"
                    },
                    "subviews": []
                },
                {
                    "type": "label",
                    "style": {
                        "font": "body",
                        "textColor": "textSecondary",
                        "numberOfLines": 0
                    },
                    "content": {
                        "text": "Контент загружен по key swift-market/catalog"
                    },
                    "subviews": []
                },
                {
                    "type": "stack",
                    "layout": {
                        "axis": "horizontal",
                        "spacing": "xs"
                    },
                    "subviews": [
                        {
                            "type": "button",
                            "action": {
                                "type": "print",
                                "message": "BDUI: category all"
                            },
                            "content": {
                                "title": "Все",
                                "buttonStyle": "primary"
                            },
                            "subviews": []
                        },
                        {
                            "type": "button",
                            "action": {
                                "type": "print",
                                "message": "BDUI: category electronics"
                            },
                            "content": {
                                "title": "Электроника",
                                "buttonStyle": "secondary"
                            },
                            "subviews": []
                        }
                    ]
                },
                {
                    "type": "view",
                    "style": {
                        "borderColor": "border",
                        "borderWidth": 1,
                        "cornerRadius": "card",
                        "backgroundColor": "card"
                    },
                    "layout": {
                        "contentInsets": {
                            "top": 12,
                            "left": 12,
                            "right": 12,
                            "bottom": 12
                        }
                    },
                    "subviews": [
                        {
                            "type": "stack",
                            "layout": {
                                "axis": "vertical",
                                "spacing": "xs"
                            },
                            "subviews": [
                                {
                                    "type": "label",
                                    "style": {
                                        "font": "heading",
                                        "textColor": "textPrimary"
                                    },
                                    "content": {
                                        "text": "AirPods Pro 3"
                                    },
                                    "subviews": []
                                },
                                {
                                    "type": "label",
                                    "style": {
                                        "font": "body",
                                        "textColor": "textSecondary",
                                        "numberOfLines": 0
                                    },
                                    "content": {
                                        "text": "Беспроводные наушники с ANC"
                                    },
                                    "subviews": []
                                },
                                {
                                    "type": "label",
                                    "style": {
                                        "font": "price",
                                        "textColor": "primary"
                                    },
                                    "content": {
                                        "text": "24 990 ₽"
                                    },
                                    "subviews": []
                                },
                                {
                                    "type": "button",
                                    "action": {
                                        "type": "route",
                                        "route": "swift-market/product"
                                    },
                                    "content": {
                                        "title": "Открыть BDUI Product",
                                        "buttonStyle": "secondary"
                                    },
                                    "subviews": []
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
}
```

Превращается вот в это:

![Simulator Screenshot - iPhone 17 Pro - 2026-04-29 at 17.59.35.png](/Users/daniil/Desktop/swift_market/swift_market/Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202026-04-29%20at%2017.59.35.png)


