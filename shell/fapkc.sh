# fapk_channel.sh
flutter build apk --no-sound-null-safety --dart-define=APP_CHANNEL=$1
cd build/app/outputs/apk/release/
# 这里的路径要修改为自己的路径
cp -R *.apk /Users/lylens/Desktop/apk/$1/
# 这里的路径要修改为自己的路径
cd /Users/lylens/Desktop/apk/$1/
open .