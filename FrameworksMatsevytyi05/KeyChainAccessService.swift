import Security
import Foundation
import LocalAuthentication

class KeyChainAccessService {
    static let shared = KeyChainAccessService()
    @Published var biometryApproved = false

    func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        
    }

    func get(key: String) -> String? {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        
        if SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == noErr,
           let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    func verifyLocalBiometry() {
        var context = LAContext()
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            
            // Fall back to a asking for username and password.
            // ...
            return
        }
        Task {
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Log in to your account")
                self.biometryApproved = true
            } catch let error {
                print(error.localizedDescription)
                // Fall back to a asking for username and password.
                // ...
            }
        }
    }
    
       func saveSecureTask(id: String, text: String) {
           guard let data = text.data(using: .utf8), self.biometryApproved else { return }

           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: id,
               kSecValueData as String: data,
           ]

           SecItemDelete(query as CFDictionary) // оновлення
           let status = SecItemAdd(query as CFDictionary, nil)
           if status != errSecSuccess {
               print("Error saving secure task: \(status)")
           }
       }

       func getSecureTask(id: String) -> String? {
           
           if !self.biometryApproved { return nil }
           
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: id,
               kSecReturnData as String: true,
               kSecMatchLimit as String: kSecMatchLimitOne,
           ]

           var dataTypeRef: AnyObject?
           if SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == noErr,
              let data = dataTypeRef as? Data {
               return String(data: data, encoding: .utf8)
           }
           return nil
       }
    
    

       func deleteSecureTask(id: String) {
           let query: [String: Any] = [
               kSecClass as String: kSecClassGenericPassword,
               kSecAttrAccount as String: id
           ]
           SecItemDelete(query as CFDictionary)
       }

}
