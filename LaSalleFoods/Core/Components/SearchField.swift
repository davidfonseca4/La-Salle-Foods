//
//  SearchField.swift
//  LaSalleFoods
//
//  Campo de búsqueda reutilizable con el estilo gris claro de la paleta.
//

import SwiftUI

struct SearchField: View {
    var placeholder: String = "Buscar"
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColor.textPlaceholder)
            TextField(placeholder, text: $text)
                .font(AppFont.body())
                .foregroundStyle(AppColor.textPrimary)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.textPlaceholder)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 48)
        .background(AppColor.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }
}

#Preview {
    SearchField(text: .constant(""))
        .padding()
        .background(AppColor.background)
}
