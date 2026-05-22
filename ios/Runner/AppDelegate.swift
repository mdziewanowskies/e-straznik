import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Konfiguruj Firebase EAGER — przed Flutter pluginami, żeby
    // FirebaseMessaging było gotowe zanim iOS wywoła APNS callback.
    // Wzorzec FlutterImplicitEngineDelegate rejestruje pluginy późno
    // (po didFinishLaunching), przez co auto-proxy Firebase nie zdąży
    // zaswizzlować i tracimy token APNS.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // Ręcznie przekazujemy APNS token do Firebase Messaging. Nawet gdyby
  // auto-proxy (FirebaseAppDelegateProxyEnabled=true) zadziałał, ten override
  // i tak jest wołany pierwszy — przekazujemy token jawnie i logujemy.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
    NSLog("[APNS] device token zarejestrowany: \(String(tokenHex.prefix(16)))… (len=\(deviceToken.count))")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[APNS] rejestracja NIE udała się: \(error.localizedDescription)")
    NSLog("[APNS] error details: \((error as NSError).userInfo)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
