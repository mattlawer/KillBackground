# executer pour compilation

clear

cd /Users/mathieu/Desktop/Developer/iPhone/JBDev/Tweaks/KillBackground/
#ln -s /Users/mathieu/Desktop/Developer/iPhone/JBDev/theos ./theos
#mv ./Tweak.xm ./Tweak.m
#ln -s ./Tweak.m ./Tweak.xm

make -f Makefile

mkdir -p ./layout/DEBIAN
cp ./control ./layout/DEBIAN
chmod -R 755 ./layout/DEBIAN

mkdir -p ./layout/Library/PreferenceLoader/Preferences
cp ./KillBackgroundPreferences/entry.plist ./layout/Library/PreferenceLoader/Preferences/KillBackgroundPreferences.plist

mkdir -p ./layout/Library/PreferenceBundles/KillBackgroundPreferences.bundle
cp ./KillBackgroundPreferences/Resources/*.* ./layout/Library/PreferenceBundles/KillBackgroundPreferences.bundle
cp ./KillBackgroundPreferences/obj/KillBackgroundPreferences ./layout/Library/PreferenceBundles/KillBackgroundPreferences.bundle

mkdir -p ./layout/Library/MobileSubstrate/DynamicLibraries
cp ./KillBackground.plist ./layout/Library/MobileSubstrate/DynamicLibraries
cp ./obj/KillBackground.dylib ./layout/Library/MobileSubstrate/DynamicLibraries

sudo find ./ -name ".DS_Store" -depth -exec rm {} \;

export COPYFILE_DISABLE=true
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true

dpkg-deb -b layout
mv ./layout.deb ./KillBackground.deb
