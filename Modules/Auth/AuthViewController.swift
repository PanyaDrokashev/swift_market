import UIKit

final class AuthViewController: UIViewController, AuthView {
    private var presenter: AuthPresenterProtocol
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let emailTextField = UITextField()
    private let passwordTextField = UITextField()
    private let errorLabel = UILabel()
    private let loginButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var keyboardObserver: NSObjectProtocol?
    private var serviceErrorMessage: String?
    private var isLoading = false
    private var isLoginAllowedByState = true

    init(presenter: AuthPresenterProtocol) {
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
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 0

        [emailTextField, passwordTextField].forEach {
            $0.borderStyle = .roundedRect
            $0.autocorrectionType = .no
            $0.autocapitalizationType = .none
            $0.clearButtonMode = .whileEditing
            $0.adjustsFontForContentSizeCategory = true
            $0.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }

        emailTextField.placeholder = "Email"
        emailTextField.textContentType = .username
        emailTextField.keyboardType = .emailAddress
        emailTextField.returnKeyType = .next
        emailTextField.accessibilityIdentifier = "auth.email"

        passwordTextField.placeholder = "Пароль"
        passwordTextField.textContentType = .password
        passwordTextField.isSecureTextEntry = true
        passwordTextField.returnKeyType = .go
        passwordTextField.accessibilityIdentifier = "auth.password"

        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.textColor = .systemRed
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        loginButton.configuration = .filled()
        loginButton.configuration?.title = "Войти"
        loginButton.configuration?.cornerStyle = .large
        loginButton.configuration?.imagePadding = 8
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        loginButton.accessibilityIdentifier = "auth.loginButton"

        activityIndicator.hidesWhenStopped = true

        stackView.axis = .vertical
        stackView.spacing = 16
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
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(loginButton)
        buttonContainer.addSubview(activityIndicator)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordTextField)
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

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

            loginButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            loginButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            loginButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: loginButton.trailingAnchor, constant: -16)
        ])

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(didTapOutside))
        dismissTap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(dismissTap)
    }

    private func setupActions() {
        emailTextField.delegate = self
        passwordTextField.delegate = self
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        emailTextField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
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

        if emailTextField.text?.isEmpty ?? true {
            emailTextField.text = viewModel.prefilledEmail
        }

        serviceErrorMessage = errorMessage
        self.isLoading = isLoading
        isLoginAllowedByState = viewModel.isLoginEnabled
        emailTextField.isEnabled = !isLoading
        passwordTextField.isEnabled = !isLoading
        refreshValidationUI()

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
        let bottomInset = max(0, intersection.height - view.safeAreaInsets.bottom) + 16

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
    private func textFieldsDidChange() {
        serviceErrorMessage = nil
        refreshValidationUI()
    }

    private func submitLogin() {
        guard validationMessage == nil else {
            refreshValidationUI()
            return
        }

        presenter.didTapLogin(
            email: emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            password: passwordTextField.text ?? ""
        )
    }

    private func refreshValidationUI() {
        let validationMessage = validationMessage
        let visibleErrorMessage = validationMessage ?? serviceErrorMessage

        errorLabel.text = visibleErrorMessage
        errorLabel.isHidden = visibleErrorMessage == nil
        loginButton.isEnabled = isLoginAllowedByState && !isLoading && validationMessage == nil

        let isEmailInvalid = validationMessage != nil
        emailTextField.layer.cornerRadius = 10
        emailTextField.layer.borderWidth = isEmailInvalid ? 1 : 0
        emailTextField.layer.borderColor = isEmailInvalid ? UIColor.systemRed.cgColor : UIColor.clear.cgColor
    }

    private var validationMessage: String? {
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard !email.isEmpty else {
            return nil
        }

        guard Self.isValidEmail(email) else {
            return "Введите корректный email"
        }

        guard !password.isEmpty else {
            return nil
        }

        return nil
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            submitLogin()
        }
        return true
    }
}
