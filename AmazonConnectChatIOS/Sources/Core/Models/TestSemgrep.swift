import CryptoKit
import Foundation

let password     = "some password here"
let saltData = Data(bytes: [0x13, 0x37, 0x37, 0x13, 0x90, 0x90, 0x90, 0x1])

let keyLength = 16
let rounds       = 50000
let algorithm = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1)

var a = 139999
var rounds1 = UInt32(a)

CCKeyDerivationPBKDF(
    CCPBKDFAlgorithm(kCCPBKDF2),
    password,
    passData.count,
    // ruleid: hardcoded-salt
    saltData,
    saltData.count,
    algorithm,
    rounds1,
    keyBuf,
    count)

  let someStr = "my salt & pepper"
  let mySalt: Data = someStr.data(using:String.Encoding.utf8)!
CCKeyDerivationPBKDF(
    CCPBKDFAlgorithm(kCCPBKDF2),
    NSString(string: "foobar").UTF8String,
    passData.count,
    // ruleid: hardcoded-salt
    mySalt,
    mySalt.count,
    algorithm,
    UInt32(13099),
    keyBuf,
    count)

rounds1 = 1600000

CCKeyDerivationPBKDF(
    CCPBKDFAlgorithm(kCCPBKDF2),
    password,
    passData.count,
    // ruleid: hardcoded-salt
    saltData,
    saltData.count,
    algorithm,
    UInt32(rounds1),
    keyBuf,
    count)

var someSalt = "I want some crypto".data(using: .utf8)!
let somePrivateKey = Curve25519.KeyAgreement.PrivateKey()
let somePublicKey = somePrivateKey.publicKey

let samePrivateKey = Curve25519.KeyAgreement.PrivateKey()
let samePublicKey = samePrivateKey.publicKey

let someSharedSecret = try! somePrivateKey.sharedSecretFromKeyAgreement(with: samePublicKey)
let sSymmetricKey = someSharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
    // ruleid: hardcoded-salt
    salt: someSalt,
    sharedInfo: Data(),
    outputByteCount: 32)

let plaintext = "Lorem ipsum dolor".data(using: .utf8)!

let ciphertext = try! ChaChaPoly.seal(plaintext, using: sSymmetricKey,
// ruleid: hardcoded-salt
nonce: someSalt).combined

let sameSharedSecret = try! samePrivateKey.sharedSecretFromKeyAgreement(with: somePublicKey)
let sameSymmetricKey = sameSharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
    // ruleid: hardcoded-salt
    salt: someSalt,
    sharedInfo: Data(),
    outputByteCount: 32)

let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedData)
let decryptedData = try! ChaChaPoly.open(sealedBox, using: sameSymmetricKey)
let decryptedPlaintext = String(data: decryptedData, encoding: .utf8)!


// AES-GCM
let nonce = try! AES.GCM.Nonce(data: Data(base64Encoded: "foobarNonce==")!)
let tag = Data(base64Encoded: "fYj==")!

let sealedBox = try! AES.GCM.seal(
    plain.data(using: .utf8)!,
    using: key, 
    // ruleid: hardcoded-salt
    nonce: nonce, 
    authenticating: tag)

let c = []
for i in 1...16 {
    let randomInt = Int.random(in: 0..<256)
    c.append(randomInt)
}

let otherNonce = Data(bytes: c)

let otherNonce = try! AES.GCM.Nonce(data: otherNonce)
let tag = Data(base64Encoded: "fYj==")!

let sealedBox = try! AES.GCM.seal(
    plain.data(using: .utf8)!,
    using: key, 
    // ok: hardcoded-salt
    nonce: otherNonce, 
    authenticating: tag)


let prefs = WKPreferences()
// ruleid: swift-webview-config-allows-js-open-windows
prefs.JavaScriptCanOpenWindowsAutomatically  = true
let config = WKWebViewConfiguration()
config.defaultWebpagePreferences = prefs

WKWebView(frame: .zero, configuration: config)

let prefs2 = WKPreferences()
prefs2.JavaScriptCanOpenWindowsAutomatically  = true
// okid: swift-webview-config-allows-js-open-windows
prefs2.JavaScriptCanOpenWindowsAutomatically  = false
let config = WKWebViewConfiguration()
config.defaultWebpagePreferences = prefs2

WKWebView(frame: .zero, configuration: config)



// Generate a random encryption key
var key = Data(count: 64)
_ = key.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) in
    SecRandomCopyBytes(kSecRandomDefault, 64, pointer.baseAddress!) }
// Configure for an encrypted realm
// ok: swift-hardcoded-realm-key
var config = Realm.Configuration(encryptionKey: key)
do {
    // Open the encrypted realm
    let realm = try Realm(configuration: config)
    // ... use the realm as normal ...
} catch let error as NSError {
    // If the encryption key is wrong, `error` will say that it's an invalid database
    fatalError("Error opening realm: \(error.localizedDescription)")
}

let plaintext = "Lorem ipsum dolor".data(using: .utf8)!

let keyData = Data(base64Encoded: "foobarNonce==")!


// ruleid: swift-hardcoded-realm-key
var config = Realm.Configuration(encryptionKey: keyData)

let i = generateRandomKeyDataBase64()
let keyData2 = Data(base64Encoded: i)!

// ok: swift-hardcoded-realm-key
var config2 = Realm.Configuration(encryptionKey: keyData2)



// ruleid: swift-hardcoded-realm-key
var config = Realm.Configuration(encryptionKey: plaintext)


let newKey = Data(bytes: [0x13, 0x37, 0x37, 0x13, 0x90, 0x90, 0x90, 0x1])


// ruleid: swift-hardcoded-realm-key
var config = Realm.Configuration(encryptionKey: newKey)


let c = []
for i in 1...16 {
    let randomInt = Int.random(in: 0..<256)
    c.append(randomInt)
}

let anotherKey = Data(bytes: c)
// ok: swift-hardcoded-realm-key
var config = Realm.Configuration(encryptionKey: anotherKey)

let newKey = Data(bytes: [0x13, 0x37, 0x37, 0x13, 0x90, 0x90, 0x90, 0x1])

var config = Realm.Configuration()
// ruleid: swift-hardcoded-realm-key
config.encryptionKey = newKey