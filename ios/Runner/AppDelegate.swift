import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Most natywny do Darta — żeby zobaczyć w UI co APNS naprawdę zrobił
  // (czy callback w ogóle się odpalił, jaki błąd zwrócił Apple).
  static var lastApnsEvent: String = "idle"
  static var lastApnsValue: String = ""
  static var apnsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    AppDelegate.apnsChannel = FlutterMethodChannel(
      name: "estraznik/apns",
      binaryMessenger: engineBridge.binaryMessenger
    )
    AppDelegate.apnsChannel?.setMethodCallHandler { call, result in
      switch call.method {
      case "getState":
        result([
          "event": AppDelegate.lastApnsEvent,
          "value": AppDelegate.lastApnsValue,
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
    let prefix = String(tokenHex.prefix(16))
    NSLog("[APNS] device token zarejestrowany: \(prefix)… (len=\(deviceToken.count))")
    AppDelegate.lastApnsEvent = "registered"
    AppDelegate.lastApnsValue = "\(prefix)… (\(deviceToken.count) bytes)"
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let ns = error as NSError
    let msg = "\(error.localizedDescription) [domain=\(ns.domain) code=\(ns.code)]"
    NSLog("[APNS] rejestracja NIE udała się: \(msg)")
    NSLog("[APNS] userInfo: \(ns.userInfo)")
    AppDelegate.lastApnsEvent = "failed"
    AppDelegate.lastApnsValue = msg
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
