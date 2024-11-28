import 'package:firebase_core/firebase_core.dart';

class FirebaseInitializer {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCzpTnYoB9h48E4O0UYI9ch6nNTxh4Ro8c", // Tu clave API
        appId: "1:620179221541:android:vencemio-a4759", // Lo encuentras en google-services.json
        messagingSenderId: "620179221541",
        projectId: "vencemio-a4759",
      ),
    );
  }
}
