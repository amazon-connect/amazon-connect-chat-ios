import Foundation

class DatabaseConnection {
    func connect() {
        let username = "admin"
        let password = "secretPassword123"  // Hardcoded password, potential security risk
        // Code to establish a database connection
        print("Connecting with username \(username) and password \(password)")
    }
}

let dbConnection = DatabaseConnection()
dbConnection.connect()