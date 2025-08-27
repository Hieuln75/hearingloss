@echo off
set PATH=C:\Users\hieuln\Downloads\flutter\bin;%PATH%

D:
cd my_app
flutter build web
xcopy build\web dist /E /I /Y
git add .
git commit -m "cap nhat phien ban moi"
git push

