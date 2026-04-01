import Foundation

struct AuthEmailValidator: AuthEmailValidating {
    func validate(email: String) -> AuthEmailValidationResult {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            return .valid
        }

        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        let isValid = trimmedEmail.range(of: pattern, options: .regularExpression) != nil

        return isValid ? .valid : .invalid(message: "Введите корректный email")
    }
}
