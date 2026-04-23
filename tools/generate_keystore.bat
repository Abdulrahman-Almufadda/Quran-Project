@echo off
REM ============================================================
REM  خطوة 1: توليد مفتاح التوقيع (Keystore)
REM  شغّل هذا الملف مرة واحدة فقط واحفظ كلمة المرور
REM ============================================================

SET KEYSTORE_PATH=..\android\app\upload-keystore.jks
SET KEY_ALIAS=quran-key
SET DNAME="CN=Abdulrahman Almufadda, OU=Dev, O=Sanaam, L=Riyadh, S=Riyadh, C=SA"

echo.
echo ============================================================
echo  توليد Keystore لتطبيق القرآن الكريم
echo ============================================================
echo.
echo  ستُسأل عن كلمة مرور - اختر كلمة قوية واحفظها جيداً
echo  ستحتاجها في كل مرة تبني فيها نسخة جديدة
echo.

keytool -genkey -v ^
  -keystore "%KEYSTORE_PATH%" ^
  -storetype JKS ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias "%KEY_ALIAS%" ^
  -dname %DNAME%

echo.
echo ============================================================
echo  تم إنشاء الـ Keystore في:
echo  android\app\upload-keystore.jks
echo.
echo  الخطوة التالية: شغّل setup_signing.bat
echo ============================================================
pause
