//
//  AuthService.swift
//  FrameworksMatsevytyi05
//
//  Created by Andrii Matsevytyi on 21.10.2025.
//

import Foundation

@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false

    func tryAutoLogin() async {
        if
            let poshta = KeyChainAccessService.shared.get(key: "poshta"),
            let password = KeyChainAccessService.shared.get(key: "password")
        {
            if await login(poshta: poshta, password: password) {
                isAuthenticated = true
                return
            }
            
        }
        else {
            isAuthenticated = false
            return
        }
    }

    func login(poshta: String, password: String) async -> Bool {

        guard let url = URL(string: "http://127.0.0.1:8080/auth") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["poshta": poshta, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print(data, response)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                
                KeyChainAccessService.shared.save(key: "poshta", value: poshta)
                KeyChainAccessService.shared.save(key: "password", value: password)
                
                return true
            }
        } catch {
            print("Login error: \(error.localizedDescription)")
        }
        return false
    }
}
