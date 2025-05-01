import GoogleMaps
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_IOS_API_KEY"] {
      GMSServices.provideAPIKey(apiKey)
    } else {
      print("Warning: GOOGLE_MAPS_IOS_API_KEY not found in environment variables")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}