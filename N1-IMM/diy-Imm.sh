#!/bin/bash

# ============ 清理 feeds 中旧版本或冲突插件 ============
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}

# 清理临时克隆目录
rm -rf clone/amlogic clone/openclash clone/passwall clone/passwall-packages

# ============ 添加插件源码 ============

# Amlogic
git clone --depth=1 https://github.com/ophub/luci-app-amlogic clone/amlogic || exit 1
cp -rf clone/amlogic/luci-app-amlogic feeds/luci/applications/

# MosDNS
git clone -b v5-lua --single-branch --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns || exit 1

# Passwall & Passwall2
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages || exit 1
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci || exit 1
#git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2 || exit 1

# OpenClash（只拉取 luci-app-openclash 子目录）
git clone --depth=1 --filter=blob:none --sparse https://github.com/vernesong/OpenClash clone/openclash || exit 1
cd clone/openclash && git sparse-checkout set luci-app-openclash && cd ../..
cp -rf clone/openclash/luci-app-openclash feeds/luci/applications/

# 主题（拉取最新 Argon 主题和配置插件）
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon || exit 1
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config || exit 1

# OpenList
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2.git package/openlist || exit 1

# 清理临时克隆目录
rm -rf clone

# ============ 在 .config 中追加插件/依赖/分区/主题设置 ============
cat >> .config <<EOF
# 必要依赖
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_kmod-tun=y

# OpenList 核心 + LuCI
CONFIG_PACKAGE_openlist=y
CONFIG_PACKAGE_luci-app-openlist2=y

# Passwall
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-mosdns=y

# 主题
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_LUCI_THEME="argon"

# OpenClash
CONFIG_PACKAGE_luci-app-openclash=y

# 固件分区设置（内核64MB，RootFS 2048MB）
CONFIG_TARGET_KERNEL_PARTSIZE=64
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
EOF

# ============ 强制设置默认主题为 Argon ============
# 修改默认设置文件（存在才修改，不存在则跳过）
if [ -f package/lean/default-settings/files/zzz-default-settings ]; then
    sed -i "s/luci.main.mediaurlbase=.*/luci.main.mediaurlbase='\/luci-static\/argon'/" package/lean/default-settings/files/zzz-default-settings
fi

# 如果使用其他源码，尝试直接创建默认主题设置
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-default-theme <<'EOT'
#!/bin/sh
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci
exit 0
EOT
chmod +x package/base-files/files/etc/uci-defaults/99-default-theme
