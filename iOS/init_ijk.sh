# setup ijkPlayer environment, it has  steps

ijk_source_path='https://github.com/Bilibili/ijkplayer'
ijk_local_path='../ijkplayer/'
ijk_local_ios_path='../ijkplayer/ios/'
ijk_init_ios_sh_name="init-ios.sh"
current_path = `pwd`
proj_root_path = "${current_path}"

setup_step_success=1

# step 1, pull the ijkPlayer source code
function pull_ijk_code() {
    if [ -e ${ijk_local_path} ]; then
        read -n 1 -p "已经存在ijkplayer文件夹，是否删除以下载最新ijk源码 ? 1/0  " res
        echo ""
        if [ ${res} != 1 ]; then
            echo "已经存在的文件夹不让删除，什么都不会发生哦"
            setup_step_success=0
            return
        fi
    fi
    
    echo "正在删除目录${ijk_local_path}"
        rm -rf ${ijk_local_path}
    echo "已经删除目录${ijk_local_path}"
    
    echo "开始下载ijk源码"
        git clone ${ijk_source_path} ${ijk_local_path}
    echo "下载ijk源码结束"
}

# step 2 run ijk init_ios.sh and compile ffmpeg
function run_ijk_init_sh() {
    cd ${ijk_local_path}
    echo "开始执行${ijk_init_ios_sh_name}"
        sh "${ijk_init_ios_sh_name}"
    echo "结束执行${ijk_init_ios_sh_name}"
    
    cd "ios/"
    echo "清理ffmpeg编译环境"
        sh ./compile-ffmpeg.sh clean
    echo "ffmpeg编译"
        sh ./compile-ffmpeg.sh all
    echo "ffmpeg编译完成"
}

echo "准备开始！"

echo "执行步骤1： 拉取ijk最新版本代码"
pull_ijk_code

if [ ${setup_step_success} == 0 ]; then
    echo "流程结束，未拉取新代码"
    exit
fi

echo "执行步骤2： 初始化ijk环境，编译ffmpeg源码"
run_ijk_init_sh

echo "执行步骤3：编译ijkplayer框架，生成framework"
cd ../../iOS/
sh build_ijk.sh

echo "初始化完成"
open QGVAPlayerDemo/QGVAPlayerDemo.xcodeproj

