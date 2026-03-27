import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    let style: ButtonStyleType
    let action: () -> Void
    var isDisabled: Bool = false
    
    enum ButtonStyleType {
        case primary
        case secondary
        case success
        case warning
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return Theme.Colors.primary
            case .secondary:
                return Color.gray
            case .success:
                return Theme.Colors.success
            case .warning:
                return Theme.Colors.warning
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(Theme.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(isDisabled ? Color.gray.opacity(0.3) : style.backgroundColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .disabled(isDisabled)
    }
}
