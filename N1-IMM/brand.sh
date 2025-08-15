#!/bin/bash
# 品牌替换脚本 - 将所有 OpenWrt/ImmortalWrt 品牌替换为 N1_OS

BRAND="N1_OS"

cd openwrt || exit 1

# 修改 /etc/openwrt_release
if [ -f package/base-files/files/etc/openwrt_release ]; then
    sed -i "s|DISTRIB_ID='ImmortalWrt'|DISTRIB_ID='${BRAND}'|g" package/base-files/files/etc/openwrt_release
    sed -i "s|DISTRIB_RELEASE='.*'|DISTRIB_RELEASE='${BRAND}'|g" package/base-files/files/etc/openwrt_release
fi

# 修改 banner
if [ -f package/base-files/files/etc/banner ]; then
    sed -i "s|ImmortalWrt|${BRAND}|g" package/base-files/files/etc/banner
    sed -i "s|OpenWrt|${BRAND}|g" package/base-files/files/etc/banner
fi

# 修改 LuCI 配置文件
LUCI_CFG="feeds/luci/modules/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CFG" ]; then
    sed -i "s|ImmortalWrt|${BRAND}|g" "$LUCI_CFG"
    sed -i "s|OpenWrt|${BRAND}|g" "$LUCI_CFG"
fi

# 修改所有 po 翻译文件
find feeds/luci/modules/luci-base/po -type f -name "*.po" -print0 | \
    xargs -0 sed -i "s|ImmortalWrt|${BRAND}|g"
find feeds/luci/modules/luci-base/po -type f -name "*.po" -print0 | \
    xargs -0 sed -i "s|OpenWrt|${BRAND}|g"

# 修改登录页面 HTML
LOGIN_VIEW="feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm"
if [ -f "$LOGIN_VIEW" ]; then
    sed -i "s|ImmortalWrt|${BRAND}|g" "$LOGIN_VIEW"
    sed -i "s|OpenWrt|${BRAND}|g" "$LOGIN_VIEW"
fi

echo "✅ 品牌替换完成：所有界面已更改为 ${BRAND}"
