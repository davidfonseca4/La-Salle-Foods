//
//  SupabaseManager.swift
//  LaSalleFoods
//
//  Punto único de acceso al cliente de Supabase. La llave es pública por
//  diseño (la seguridad real la dan las políticas RLS de cada tabla).
//

import Foundation
import Supabase

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://pftnnkrpufxpzoadbgxu.supabase.co")!,
        supabaseKey: "sb_publishable_0PghU_jyiuPHujQnGCqNVw_KudLnah6"
    )
}
