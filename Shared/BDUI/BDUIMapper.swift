import UIKit

struct DefaultBDUINodeDecoder: BDUINodeDecoding {
    private let decoder: JSONDecoder

    init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func decodeNode(from data: Data) throws -> BDUINode {
        try decoder.decode(BDUINode.self, from: data)
    }
}

final class BDUIMapper: BDUIMapperProtocol {
    weak var actionHandler: BDUIActionHandling?

    func makeView(from node: BDUINode) -> UIView {
        let mapped = mapView(node)
        applyLayout(node.layout, to: mapped)
        applyStyle(node.style, to: mapped)
        bindActionIfNeeded(for: node, in: mapped)
        return mapped
    }

    private func mapView(_ node: BDUINode) -> UIView {
        switch node.type {
        case .view:
            return makeContainer(for: node)
        case .stack:
            return makeStack(for: node)
        case .label:
            return makeLabel(for: node)
        case .button:
            return makeButton(for: node)
        case .textField:
            return makeTextField(for: node)
        case .stateView:
            return makeStateView(for: node)
        case .spacer:
            return makeSpacer(for: node)
        }
    }

    private func makeContainer(for node: BDUINode) -> UIView {
        let root = UIView()
        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .fill
        content.distribution = .fill
        content.spacing = 0
        content.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(content)

        let insets = node.layout?.contentInsets?.uiInsets ?? .zero
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: root.topAnchor, constant: insets.top),
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: insets.left),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -insets.right),
            content.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -insets.bottom)
        ])

        node.subviews
            .map { makeView(from: $0) }
            .forEach { content.addArrangedSubview($0) }

        return root
    }

    private func makeStack(for node: BDUINode) -> UIView {
        let stack = UIStackView()
        stack.axis = node.layout?.axis?.value ?? .vertical
        stack.spacing = node.layout?.spacing?.value ?? DS.Spacing.s
        stack.alignment = node.layout?.alignment?.value ?? .fill
        stack.distribution = node.layout?.distribution?.value ?? .fill

        node.subviews
            .map { makeView(from: $0) }
            .forEach { stack.addArrangedSubview($0) }

        if let insets = node.layout?.contentInsets {
            stack.isLayoutMarginsRelativeArrangement = true
            stack.layoutMargins = insets.uiInsets
        }

        return stack
    }

    private func makeLabel(for node: BDUINode) -> UIView {
        let label = UILabel()
        label.text = node.content?.text ?? node.content?.title
        label.numberOfLines = node.style?.numberOfLines ?? 0
        label.textAlignment = node.style?.alignment?.value ?? .natural
        label.textColor = node.style?.textColor?.value ?? DS.Colors.textPrimary
        label.font = node.style?.font?.font() ?? DS.Typography.body()
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    private func makeButton(for node: BDUINode) -> UIView {
        let button = DSButton()
        button.configure(
            .init(
                title: node.content?.title ?? node.content?.text ?? "",
                style: node.content?.buttonStyle?.value ?? .primary,
                isEnabled: node.content?.isEnabled ?? true
            )
        )
        return button
    }

    private func makeTextField(for node: BDUINode) -> UIView {
        let field = DSTextField()
        let content = DSTextField.Content(
            title: node.content?.title ?? "",
            placeholder: node.content?.placeholder ?? "",
            isSecureTextEntry: node.content?.isSecureTextEntry ?? false
        )
        field.configure(
            .init(
                content: content,
                errorMessage: node.content?.message,
                isEnabled: node.content?.isEnabled ?? true
            )
        )
        return field
    }

    private func makeStateView(for node: BDUINode) -> UIView {
        let stateView = DSStateView()
        let message = node.content?.message ?? ""
        let retryTitle = node.content?.retryTitle ?? "Повторить"

        let state: DSStateView.State
        switch node.content?.state ?? .hidden {
        case .hidden:
            state = .hidden
        case .loading:
            state = .loading(message: message)
        case .empty:
            state = .empty(message: message)
        case .error:
            state = .error(message: message, retryTitle: retryTitle)
        }

        stateView.configure(.init(state: state))
        return stateView
    }

    private func makeSpacer(for node: BDUINode) -> UIView {
        let spacer = UIView()
        spacer.backgroundColor = .clear
        if let height = node.layout?.height {
            spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        if let width = node.layout?.width {
            spacer.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        return spacer
    }

    private func applyStyle(_ style: BDUIStyle?, to view: UIView) {
        guard let style else { return }
        view.backgroundColor = style.backgroundColor?.value ?? view.backgroundColor
        view.layer.cornerRadius = style.cornerRadius?.value ?? view.layer.cornerRadius
        view.layer.borderColor = style.borderColor?.value.cgColor ?? view.layer.borderColor

        if let borderWidth = style.borderWidth {
            view.layer.borderWidth = borderWidth
        }

        if let hidden = style.isHidden {
            view.isHidden = hidden
        }
    }

    private func applyLayout(_ layout: BDUILayout?, to view: UIView) {
        guard let layout else { return }
        view.translatesAutoresizingMaskIntoConstraints = false

        if let width = layout.width {
            view.widthAnchor.constraint(equalToConstant: width).isActive = true
        }

        if let height = layout.height {
            view.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    private func bindActionIfNeeded(for node: BDUINode, in view: UIView) {
        guard let action = node.action else { return }

        if let control = view as? UIControl {
            control.addAction(
                UIAction { [weak actionHandler] _ in
                    actionHandler?.handle(action: action)
                },
                for: .touchUpInside
            )
        }

        if let stateView = view as? DSStateView {
            stateView.onRetry = { [weak actionHandler] in
                actionHandler?.handle(action: action)
            }
        }
    }
}

final class BDUIRenderer: BDUIRendering {
    private let decoder: BDUINodeDecoding
    private let mapper: BDUIMapperProtocol

    init(
        decoder: BDUINodeDecoding = DefaultBDUINodeDecoder(),
        mapper: BDUIMapperProtocol
    ) {
        self.decoder = decoder
        self.mapper = mapper
    }

    func render(data: Data) throws -> UIView {
        let root = try decoder.decodeNode(from: data)
        return mapper.makeView(from: root)
    }
}

final class DefaultBDUIActionHandler: BDUIActionHandling {
    var onReload: (() -> Void)?
    var onRoute: ((String) -> Void)?

    func handle(action: BDUIAction) {
        switch action.type {
        case .print:
            if let message = action.message {
                print("BDUI action: \(message)")
            }
        case .reload:
            onReload?()
        case .route:
            if let route = action.route {
                onRoute?(route)
            }
        }
    }
}
