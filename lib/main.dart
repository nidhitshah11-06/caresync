import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/reminder_service.dart';
import 'services/voice_service.dart';
import 'config/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseAnonKey,
  );

  await ReminderService.initialize();
  await VoiceService.initialize();

  runApp(const CareSync());
}

final supabase = Supabase.instance.client;

class CareSync extends StatelessWidget {
  const CareSync({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D6E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6E),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: supabase.auth.currentSession == null
          ? const LoginScreen()
          : const SplashScreen(),
    );
  }
}
```

---

**Step 5 — Paste into the empty file**

Click in the empty middle screen.

Press:
```
Ctrl + V
```

You should now see all the code appear.

---

**Step 6 — Save the file**

Press:
```
Ctrl + S
```

You will see the orange dot on the tab disappear — that means it is saved.

---

**Step 7 — Check for errors**

Look at the bottom of VS Code. It shows:
```
0 errors   0 warnings   ← perfect
```

or
```
2 errors   ← tell me what errors appear