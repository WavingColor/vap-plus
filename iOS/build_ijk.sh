#!/bin/sh

cur_path=`pwd`
LIB_PROJECT="../ijkplayer/ios/IJKMediaPlayer/IJKMediaPlayer.xcodeproj"
BUILD_DIR="${cur_path}/Build_Dir"
TARGET_NAME='IJKMediaFramework'
FRAMEWORK_NAME=${TARGET_NAME}.framework
DEBUG_IPHONEOS=${BUILD_DIR}/Debug-iphoneos/${FRAMEWORK_NAME}
DEBUG_SIMULATOR=${BUILD_DIR}/Debug-iphonesimulator/${FRAMEWORK_NAME}
RELEASE_IPHONEOS=${BUILD_DIR}/Release-iphoneos/${FRAMEWORK_NAME}
RELEASE_SIMULATOR=${BUILD_DIR}/Release-iphonesimulator/${FRAMEWORK_NAME}

DEBUG_FRAMEWORK=${cur_path}/Frameworks/Debug/${FRAMEWORK_NAME}
RELEASE_FRAMEWORK=${cur_path}/Frameworks/Release/${FRAMEWORK_NAME}

# 编译 Framwork
# $1: Debug 或 Release
# $2: iphonesimulator 或 iphoneos
# $3: 架构
function buildAction() {
    echo "start compile project: ${LIB_PROJECT} sdk: $2 Framework, arch: $3"
    xcodebuild -target ${TARGET_NAME} -project ${LIB_PROJECT} ONLY_ACTIVE_ARCH=NO -configuration $1 -sdk $2 -arch $3 BUILD_DIR=${BUILD_DIR} clean build
}

function remove_output_path() {
    if [ -d $1 ]; then
        rm -rf $1
    fi
}

function recreate_output_path() {
    remove_output_path $1
    mkdir -p $1
}

 # 合并真机与模拟器的 Framwork
 # $1: 真机 Framework
 # $2: 模拟器 Framework
 # $3: 合并 Framework
function mergeFramework() {
    echo "clear output path"
    recreate_output_path $3
    echo "copy framework headers to output path"
    cp -r $1/ $3
    echo "merge iPhoneOS and iphonesimulator framework"
    lipo -create $1/${TARGET_NAME} $2/${TARGET_NAME} -output $3/${TARGET_NAME}
}

##############
echo "clear build tmp dir"
remove_output_path $BUILD_DIR

echo "select to compile framework: \n d -> Debug; \n r -> Release \n "
read -n 1 -p "my choice: " res
echo ""

if [[ $res == d || $res == D ]]; then
    echo "start compile DEBUG framework"
    buildAction Debug iphoneos arm64
    buildAction Debug iphonesimulator x86_64
    remove_output_path $DEBUG_FRAMEWORK
    mergeFramework $DEBUG_IPHONEOS $DEBUG_SIMULATOR $DEBUG_FRAMEWORK
    echo "complete compile DEBUG framework"
fi

if [[ $res == r || $res == R ]]; then
    echo "start compile Release framework"
    buildAction Release iphoneos arm64
    buildAction Release iphonesimulator x86_64

    remove_output_path $RELEASE_FRAMEWORK
    mergeFramework $RELEASE_IPHONEOS $RELEASE_SIMULATOR $RELEASE_FRAMEWORK
    echo "complete compile Release framework"
fi

echo "finish all and delete dir: $BUILD_DIR"
rm -rf $BUILD_DIR
