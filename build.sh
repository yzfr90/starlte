#!/bin/bash

VARIANT=xx
ARCH=arm64
export KBUILD_BUILD_USER=BuildUser
export KBUILD_BUILD_HOST=BuildHost
export KBUILD_BUILD_TIMESTAMP="Mon Nov 23 00:45:00 +07 1987"
export KBUILD_COMPILER_STRING="LLVM Clang 7.0"
CCACHE=ccache
BUILD_CROSS_COMPILE=$HOME/opt/gcc-arm-8.2-2018.11-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu-
BUILD_CC=$HOME/opt/clang+llvm-7.0.0-x86_64-linux-gnu-ubuntu-16.04/bin/clang
# BUILD_CC="${BUILD_CROSS_COMPILE}gcc"
BUILD_LD=$HOME/opt/clang+llvm-7.0.0-x86_64-linux-gnu-ubuntu-16.04/bin/ld.lld
# BUILD_LD="${BUILD_CROSS_COMPILE}ld"
BUILD_JOB_NUMBER="$(nproc)"

RDIR="$(pwd)"

case ${VARIANT} in
can|duos|eur|xx)
	KERNEL_DEFCONFIG=exynos9810-starlte_defconfig
	;;
*)
	echo "Unknown variant: ${VARIANT}"
	exit 1
	;;
esac

FUNC_CLEAN_DTB()
{
	if ! [ -d ${RDIR}/arch/${ARCH}/boot/dts ] ; then
		echo "no directory : "${RDIR}/arch/${ARCH}/boot/dts""
	else
		echo "rm files in : "${RDIR}/arch/${ARCH}/boot/dts/*.dtb""
		rm ${RDIR}/arch/${ARCH}/boot/dts/exynos/*.dtb
	fi
}

FUNC_BUILD_KERNEL()
{
	echo ""
	echo "=============================================="
	echo "START : FUNC_BUILD_KERNEL"
	echo "=============================================="
	echo ""
	echo "build common config="$KERNEL_DEFCONFIG ""
	echo "build model config=SM-G960F"

	FUNC_CLEAN_DTB

	make -j$BUILD_JOB_NUMBER ARCH=${ARCH} \
			CC="${CCACHE} ${BUILD_CC}" \
			LD=$BUILD_LD \
			CROSS_COMPILE="$BUILD_CROSS_COMPILE" \
			$KERNEL_DEFCONFIG || exit -1

	make -j$BUILD_JOB_NUMBER ARCH=${ARCH} \
			CC="${CCACHE} ${BUILD_CC}" \
			LD=$BUILD_LD \
			CROSS_COMPILE="$BUILD_CROSS_COMPILE" || exit -1

	echo ""
	echo "================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "================================="
	echo ""
}

FUNC_BUILD_RAMDISK()
{
	case ${VARIANT} in
	can|duos|eur|xx)
		cp ${RDIR}/arch/${ARCH}/boot/Image ${RDIR}/aik/split_img/boot.img-zImage
		cp ${RDIR}/arch/${ARCH}/boot/dtb.img ${RDIR}/aik/split_img/boot.img-dtb
		find ${RDIR} -name "*.ko" -not -path "*/aik/ramdisk/*" -exec mv -f {} ${RDIR}/aik/ramdisk/lib/modules/ \;
		cd ${RDIR}/aik
		./fixperm.sh
		./repackimg.sh
		;;
	*)
		echo "Unknown variant: ${VARIANT}"
		exit 1
		;;
	esac
}

FUNC_BUILD_ZIP()
{
	cd ${RDIR}/out/
	case ${VARIANT} in
	can|duos|eur|xx)
		cp ${RDIR}/aik/image-new.img ${RDIR}/out/boot.img
		;;
	*)
		echo "Unknown variant: ${VARIANT}"
		exit 1
		;;
	esac

	cd ${RDIR}/out/ && zip ../g960f_kernel.zip -r *
}

# MAIN FUNCTION
rm -rf ./build.log
(
	START_TIME=`date +%s`

	FUNC_BUILD_KERNEL
	FUNC_BUILD_RAMDISK
	FUNC_BUILD_ZIP

	END_TIME=`date +%s`

	let "ELAPSED_TIME=${END_TIME}-${START_TIME}"
	echo "Total compile time was ${ELAPSED_TIME} seconds"

) 2>&1	 | tee -a ./build.log
