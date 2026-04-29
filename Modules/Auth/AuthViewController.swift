import UIKit

final class AuthViewController: UIViewController, AuthView {
    private var presenter: AuthPresenterProtocol
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    private lazy var stackView = UIStackView()
    private lazy var titleLabel = UILabel()
    private lazy var subtitleLabel = UILabel()
    private lazy var emailField = DSTextField()
    private lazy var passwordField = DSTextField()
    private lazy var errorLabel = UILabel()
    private lazy var loginButton = DSButton()
    private lazy var activityIndicator = UIActivityIndicatorView(style: .medium)
    private var keyboardObserver: NSObjectProtocol?
    private let emailFieldContent = DSTextField.Content(
        title: "Email",
        placeholder: "you@example.com",
        textContentType: .username,
        keyboardType: .emailAddress,
        returnKeyType: .next
    )
    private let passwordFieldContent = DSTextField.Content(
        title: "Пароль",
        placeholder: "Введите пароль",
        textContentType: .password,
        returnKeyType: .go,
        isSecureTextEntry: true
    )

    init(
        presenter: AuthPresenterProtocol
    ) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        title = "Авторизация"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupLayout()
        setupActions()
        setupNavigation()
        setupKeyboardObserver()
        presenter.didLoad()
    }

    deinit {
        if let keyboardObserver {
            NotificationCenter.default.removeObserver(keyboardObserver)
        }
    }

    func inject(presenter: AuthPresenterProtocol) {
        self.presenter = presenter
    }

    func render(_ state: AuthViewState) {
        switch state {
        case .initial(let viewModel), .content(let viewModel):
            apply(viewModel: viewModel, errorMessage: nil, isLoading: false)
        case .loading(let viewModel):
            apply(viewModel: viewModel, errorMessage: nil, isLoading: true)
        case .error(let viewModel, let message):
            apply(viewModel: viewModel, errorMessage: message, isLoading: false)
        }
    }

    private func configureAppearance() {
        view.backgroundColor = DS.Colors.background
        navigationItem.largeTitleDisplayMode = .never

        titleLabel.font = DS.Typography.title()
        titleLabel.textColor = DS.Colors.textPrimary
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        subtitleLabel.font = DS.Typography.body()
        subtitleLabel.textColor = DS.Colors.textSecondary
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 0

        emailField.configure(.init(content: emailFieldContent))
        emailField.textField.accessibilityIdentifier = "auth.email"

        passwordField.configure(.init(content: passwordFieldContent))
        passwordField.textField.accessibilityIdentifier = "auth.password"

        errorLabel.font = DS.Typography.footnote()
        errorLabel.textColor = DS.Colors.error
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        loginButton.configure(
            .init(title: "Войти", style: .primary)
        )
        loginButton.accessibilityIdentifier = "auth.loginButton"

        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true

        stackView.axis = .vertical
        stackView.spacing = DS.Spacing.m
        stackView.alignment = .fill
    }

    private func setupLayout() {
        [scrollView, contentView, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(loginButton)
        buttonContainer.addSubview(activityIndicator)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(emailField)
        stackView.addArrangedSubview(passwordField)
        stackView.addArrangedSubview(errorLabel)
        stackView.addArrangedSubview(buttonContainer)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: guide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DS.Spacing.xl),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DS.Spacing.l),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DS.Spacing.l),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -DS.Spacing.l),

            loginButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            loginButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            loginButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: loginButton.trailingAnchor, constant: -DS.Spacing.s)
        ])

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(didTapOutside))
        dismissTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(dismissTap)
    }

    private func setupActions() {
        emailField.textField.delegate = self
        passwordField.textField.delegate = self
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        emailField.textField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        passwordField.textField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
    }

    private func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "BDUI",
            style: .plain,
            target: self,
            action: #selector(didTapOpenBDUI)
        )
    }

    private func setupKeyboardObserver() {
        keyboardObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification)
        }
    }

    private func apply(viewModel: AuthInitialViewModel, errorMessage: String?, isLoading: Bool) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle

        if emailField.text?.isEmpty ?? true {
            emailField.text = viewModel.prefilledEmail
        }

        emailField.configure(
            .init(
                content: emailFieldContent,
                errorMessage: viewModel.emailValidationMessage,
                isEnabled: viewModel.isFieldsEnabled
            )
        )
        passwordField.configure(
            .init(
                content: passwordFieldContent,
                isEnabled: viewModel.isFieldsEnabled
            )
        )

        let displayedServiceError = errorMessage ?? viewModel.serviceErrorMessage
        errorLabel.text = displayedServiceError
        errorLabel.isHidden = displayedServiceError == nil
        loginButton.configure(
            .init(
                title: "Войти",
                style: .primary,
                isEnabled: viewModel.isLoginEnabled
            )
        )

        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func handleKeyboard(notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else {
            return
        }

        let keyboardInView = view.convert(endFrame, from: nil)
        let intersection = view.bounds.intersection(keyboardInView)
        let bottomInset = max(0, intersection.height - view.safeAreaInsets.bottom) + DS.Spacing.s

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveValue << 16)
        ) {
            self.scrollView.contentInset.bottom = bottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    @objc
    private func didTapOutside() {
        view.endEditing(true)
    }

    @objc
    private func didTapLogin() {
        submitLogin()
    }

    @objc
    private func didTapOpenBDUI() {
        presenter.didTapOpenBDUI()
    }

    @objc
    private func textFieldsDidChange() {
        presenter.didChangeCredentials(
            email: emailField.text ?? "",
            password: passwordField.text ?? ""
        )
    }

    private func submitLogin() {
        presenter.didTapLogin(
            email: emailField.text ?? "",
            password: passwordField.text ?? ""
        )
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField.textField {
            passwordField.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            submitLogin()
        }
        return true
    }
}
