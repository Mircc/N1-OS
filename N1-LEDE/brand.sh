#!/bin/bash
# 品牌与版本信息修改

OPENWRT_VER=$(grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' include/version.mk | head -n1)
BUILD_DATE=$(date +%Y%m%d)
echo "OPENWRT_VER=$OPENWRT_VER" >> $GITHUB_ENV
echo "PACKAGED_OUTPUTDATE=$BUILD_DATE" >> $GITHUB_ENV

sed -i "s/DISTRIB_ID='OpenWrt'/DISTRIB_ID='N1_OS'/g" package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_RELEASE='.*'/DISTRIB_RELEASE='${OPENWRT_VER}'/g" package/base-files/files/etc/openwrt_release
sed -i "s/OpenWrt/N1_OS/g" package/base-files/files/etc/banner

LUCI_CFG="feeds/luci/modules/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CFG" ]; then
  sed -i "s/OpenWrt/N1_OS/g" "$LUCI_CFG"
fi

find feeds/luci/modules/luci-base/po -type f -name "*.po" -exec sed -i "s/OpenWrt/N1_OS/g" {} \;

LOGIN_VIEW="feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm"
if [ -f "$LOGIN_VIEW" ]; then
  sed -i 's/OpenWrt/N1_OS/g' "$LOGIN_VIEW"
fi

echo "=============================================="
echo " 固件品牌: N1_OS"
echo " OpenWrt 版本号: $OPENWRT_VER"
echo " 编译日期: $BUILD_DATE"
echo " LuCI 网页 & 登录页面已改为 N1_OS"
echo "=============================================="
