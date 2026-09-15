import SwiftUI
import HoppaStore

/// English / Nederlands, always in their own name so a wrong tap is recoverable.
struct LanguagePicker: View {
    @Environment(LanguageStore.self) private var languages
    @Environment(\.copy) private var copy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(copy[.language])
                .typography(Typography.label(10.5))
                .foregroundStyle(Color.labelText)
            ForEach(AppLanguage.allCases) { language in
                Button {
                    languages.choose(language)
                } label: {
                    HStack {
                        Text(language.nativeName)
                            .typography(Typography.display(15))
                            .foregroundStyle(Color.text)
                        Spacer()
                        if languages.language == language {
                            Text(copy[.selected])
                                .typography(Typography.meta())
                                .foregroundStyle(Color.dimText)
                        }
                    }
                    .padding(16)
                    .background(Color.card, in: RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.pressable)
            }
        }
    }
}
