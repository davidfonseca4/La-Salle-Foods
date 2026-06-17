//
//  String+Extensions.swift
//  LaSalleFoods
//
//  Validaciones de formato reutilizadas en los formularios de auth.
//

import Foundation

extension String {
    /// El backend solo acepta correos @lasallebajio.edu.mx; validamos aquí
    /// para dar feedback inmediato en vez de esperar el error del servidor.
    var isInstitutionalEmail: Bool {
        range(of: #"^[a-zA-Z0-9._%+-]+@lasallebajio\.edu\.mx$"#, options: .regularExpression) != nil
    }
}
