import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

    // الـ secure field اللي بيمنع الـ screenshot والـ screen recording
    private var secureField: UITextField?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // نفذ بعد ما الـ window يتجهز
        DispatchQueue.main.async {
            self._applyScreenProtection()
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func _applyScreenProtection() {
        guard let window = self.window else { return }

        // UITextField بـ isSecureTextEntry = true بيخلي iOS يحجب الـ screenshot والـ recording
        let field = UITextField()
        field.isSecureTextEntry = true
        field.translatesAutoresizingMaskIntoConstraints = false
        field.isUserInteractionEnabled = false
        field.backgroundColor = .clear

        // نحط الـ field في الخلفية عشان ما يأثرش على الـ UI
        window.addSubview(field)
        window.layer.superlayer?.addSublayer(field.layer)
        field.layer.sublayers?.last?.addSublayer(window.layer)

        self.secureField = field
    }
}