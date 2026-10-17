# QatanCraft

QatanCraft هي نسخة هاتفية مفتوحة المصدر من لعبة voxel خفيفة، مبنية على محرك **ClassiCube** مع هوية Android مستقلة باسم QatanCraft. التجربة تركز على الاستكشاف والبناء داخل عوالم مكعبة، مع دعم اللمس وأداء مناسب للأجهزة المحمولة ووضع أفقي ثابت.

## ما الذي تغيّر في هذه النسخة؟

- اسم التطبيق الظاهر على Android هو `QatanCraft`.
- معرّف الحزمة مستقل: `com.abdullahqatan.qatancraft`.
- التطبيق يفتح في الوضع الأفقي لتناسب واجهة اللعب والاستكشاف.
- تم تحديث مشروع Gradle إلى Android Gradle Plugin 8.5.2 وGradle 8.7، مع compile/target SDK 35.
- أضيف سير عمل GitHub Actions لبناء APK تجريبي قابل للتنزيل من صفحة Actions.

## البناء محليًا

```bash
cd misc/android
chmod +x gradlew
./gradlew assembleDebug
```

ينتج APK في:

```text
misc/android/app/build/outputs/apk/debug/app-debug.apk
```

يتطلب البناء Java 17 وAndroid SDK مع `platforms;android-35` و`cmake;3.22.1` وNDK متوافقًا.

## المصدر والترخيص

هذه النسخة مبنية على ClassiCube، وهو مشروع مستقل غير تابع لـ Mojang أو Microsoft. يحتفظ المستودع بملف `license.txt` الأصلي وجميع إشعارات المكونات الخارجية. كود ClassiCube الأساسي مرخّص برخصة BSD-3-Clause، وهي رخصة permissive تسمح بالاستخدام والتعديل والتوزيع وفق شروط حفظ إشعارات حقوق النشر وإخلاء المسؤولية.

اسم QatanCraft وتخصيصات Android في هذا المستودع من إعداد عبدالله قحطان. لا يوحي المشروع بوجود علاقة أو اعتماد رسمي مع Mojang أو Microsoft.
