@echo off
REM ============================================================
REM  بناء نسخة الإصدار لـ Google Play
REM  شغّل هذا من مجلد المشروع الرئيسي
REM ============================================================

cd ..

echo.
echo ============================================================
echo  الخطوة 1: التأكد من وجود key.properties
echo ============================================================
IF NOT EXIST "android\app\key.properties" (
    echo.
    echo  ❌ ملف key.properties غير موجود!
    echo  انسخ android\key.properties.template إلى android\app\key.properties
    echo  ثم ضع كلمات المرور الصحيحة داخله
    echo.
    pause
    exit /b 1
)

echo  ✅ key.properties موجود

echo.
echo ============================================================
echo  الخطوة 2: تنظيف المشروع
echo ============================================================
call flutter clean

echo.
echo ============================================================
echo  الخطوة 3: بناء AAB للرفع على Google Play
echo ============================================================
call flutter build appbundle --release

echo.
echo ============================================================
IF %ERRORLEVEL% == 0 (
    echo  ✅ تم البناء بنجاح!
    echo.
    echo  ملف الرفع موجود في:
    echo  build\app\outputs\bundle\release\app-release.aab
    echo.
    echo  ارفع هذا الملف على Google Play Console
) ELSE (
    echo  ❌ فشل البناء — راجع الأخطاء أعلاه
)
echo ============================================================
echo.
pause
