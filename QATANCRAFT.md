# QatanCraft Survival

QatanCraft Survival هي لعبة بقاء وبناء مكعبة للهواتف، مبنية على محرك **Luanti** المفتوح المصدر وتستخدم محتوى **VoxeLibre** المفتوح المصدر. الهدف هو تقديم تجربة بقاء قريبة من ألعاب voxel المعروفة: جمع الموارد، التعدين، الصناعة، الزراعة، الاستكشاف، الوحوش، الجوع والصحة، وبناء العوالم.

هذه النسخة لا تستخدم كود Minecraft أو علاماته أو أصوله المملوكة. التشابه في الميكانيكيات العامة يأتي من كون Luanti وVoxeLibre مشاريع مفتوحة المصدر مستوحاة من ألعاب voxel.

## البناء

```bash
cd android
chmod +x gradlew
./gradlew assembleDebug
```

يُنشئ البناء APKs منفصلة للمعماريات المدعومة داخل:

```text
android/app/build/outputs/apk/debug/
```

ينفّذ GitHub Actions البناء تلقائيًا، ثم يرفع APKs إلى **GitHub Release مسودة** باسم `qatan-survival-<run-id>`.

## مكونات التجربة

- محرك Luanti مع دعم Android واللمس.
- VoxeLibre كلعبة بقاء افتراضية.
- اختيار VoxeLibre افتراضيًا عند أول تشغيل.
- وضع أفقي مناسب للهاتف.
- بيانات التطبيق داخل مجلد QatanCraft الخاص بالتطبيق.
- هوية Android مستقلة باسم `QatanCraft` ومعرّف `com.abdullahqatan.qatancraft`.

## التراخيص

- محرك Luanti: GNU LGPL v2.1 أو أحدث، حسب ملفات المصدر.
- محتوى VoxeLibre البرمجي: GNU GPLv3 أو أحدث.
- وسائط VoxeLibre موثقة داخل `games/voxelibre/LEGAL.md`، وتشمل تراخيص CC BY-SA وCC BY وCC0 حسب الملف.
- يجب إبقاء ملفات التراخيص والإشعارات عند إعادة التوزيع.

## النسخ السابقة

تم الاحتفاظ بنسخة ClassiCube السابقة في فرع GitHub:

```text
classicube-before-luanti-rebuild
```
