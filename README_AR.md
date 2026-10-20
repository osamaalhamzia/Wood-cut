# قصّ الألواح — نسخة Flutter

تطبيق يحسب خطة قص الألواح وعدد الألواح المطلوبة (خوارزمية Guillotine مع احتساب سماكة المنشار).

## الأرقام واللغة
- كل الأرقام إنجليزية (0-9) في الإدخال والعرض، وإذا كتب الكيبورد أرقاماً عربية (٠-٩) تتحول تلقائياً إلى إنجليزية.
- العناوين والمصطلحات والبيانات عربية وواجهة التطبيق من اليمين لليسار.

## بناء APK
### الطريقة 1: GitHub (بدون تثبيت أي شيء)
1. ارفع محتوى هذا المجلد (بعد فك الضغط) إلى مستودع GitHub جديد، وتأكد أن مجلد `.github` رُفع.
2. تبويب Actions ← Build APK ← Run workflow.
3. بعد دقائق نزّل `app-release-apk` من Artifacts وفيه `app-release.apk`.

### الطريقة 2: على جهازك (Flutter SDK + Android SDK)
```
flutter create . --project-name qass_alwah --org com.qass --platforms=android
flutter pub get
flutter build apk --release
```
(أمر create يولّد مجلد android ولا يمس ملفات lib الحالية، وإن سأل عن استبدال ملفات فاختر عدم الاستبدال).
الناتج: `build/app/outputs/flutter-apk/app-release.apk`

## هيكل الكود
- `lib/packing.dart` خوارزمية القص
- `lib/home_page.dart` الشاشة الرئيسية
- `lib/board_viz.dart` رسم مخطط اللوح
- `lib/widgets.dart` الحقول الرقمية (إنجليزية)
- `lib/utils.dart` أدوات التنسيق
- `lib/theme.dart` الألوان

## ملاحظة
النسخة الموقّعة بمفتاح debug مناسبة للتجربة والتثبيت المباشر؛ للنشر على Google Play نحتاج keystore.
