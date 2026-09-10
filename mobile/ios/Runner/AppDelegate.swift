import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let map = Self.dartDefines()
    let key = map["GOOGLE_MAP_KEY_IOS"] ?? ""
      
    GMSServices.provideAPIKey(key)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// --dart-define等で渡されたdart-defineは、Flutterのビルドスクリプトによりビルド設定の
  /// DART_DEFINES（= Info.plistのDartDefines）へ、base64エンコードされた"KEY=VALUE"の
  /// カンマ区切りとして埋め込まれる。ここではそれをデコードして辞書に変換する。
  private static func dartDefines() -> [String: String] {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "DartDefines") as? String else {
      return [:]
    }

    return raw.split(separator: ",").reduce(into: [:]) { defines, encoded in
      guard let data = Data(base64Encoded: String(encoded)),
        let decoded = String(data: data, encoding: .utf8)
      else {
        return
      }
      // 値自体に"="を含む可能性があるため、最初の"="だけで分割する
      let pair = decoded.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      guard pair.count == 2 else { return }
      defines[String(pair[0])] = String(pair[1])
    }
  }
}
