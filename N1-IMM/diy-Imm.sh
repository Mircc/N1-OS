#!/bin/bash

# Add packages
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/luci/applications/luci-app-mosdns

git clone https://github.com/ophub/luci-app-amlogic --depth=1 clone/amlogic
cp -rf clone/amlogic/luci-app-amlogic feeds/luci/applications/

git clone -b v5-lua --single-branch --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns

# git clone https://github.com/xiaorouji/openwrt-passwall --depth=1 clone/passwall
# rm -rf feeds/luci/applications/luci-app-passwall
# cp -rf clone/passwall/luci-app-passwall feeds/luci/applications/

git clone https://github.com/vernesong/OpenClash --depth=1 clone/openclash
rm -rf feeds/luci/applications/luci-app-openclash
cp -rf clone/openclash/luci-app-openclash feeds/luci/applications/

#以下为passwall相关
# 移除 openwrt feeds 自带的核心库
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages

# 移除 openwrt feeds 过时的luci版本
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2
# passwall相关结束

#主题
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# ============ 添加 luci-app-openlist2 + 核心程序 ============
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2.git package/openlist

# Clean packages
rm -rf clone

# ============ 在 .config 中开启插件/Overlay大小 ============
cat >> .config <<EOF
# OpenList 核心 + LuCI
CONFIG_PACKAGE_openlist=y
CONFIG_PACKAGE_luci-app-openlist2=y

#passwall
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-mosdns=y
#themes
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y

# OpenClash 主程序
CONFIG_PACKAGE_luci-app-openclash=y


# 必要依赖
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_kmod-tun=y

# 固件分区设置（内核64MB，RootFS 2048MB）
CONFIG_TARGET_KERNEL_PARTSIZE=64
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
EOF
