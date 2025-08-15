#!/bin/bash

# Add packages
git clone https://github.com/ophub/luci-app-amlogic --depth=1 clone/amlogic
cp -rf clone/amlogic/luci-app-amlogic feeds/luci/applications/

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

#passwall相关结束

# Clean packages
rm -rf clone
