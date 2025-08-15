#!/bin/bash
# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# ==================== 添加插件源 ====================

# 科学上网
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall

# 主题 & 主题设置
git clone -b 18.06 --single-branch --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone -b 18.06 --single-branch --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# N1 打包工具
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/amlogic

# DDNS-GO
git clone --depth=1 https://github.com/sirpdboy/luci-app-ddns-go package/ddnsgo

# MOSDNS & ALIST & LUCKY
git clone -b v5-lua --single-branch --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns
git clone -b lua --single-branch --depth 1 https://github.com/sbwml/luci-app-alist package/alist
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

# OpenList（核心+LuCI）
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2.git package/openlist

# OpenClash
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# ==================== 删除冲突包 ====================
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/luci/applications/luci-app-mosdns

# ==================== 基础系统设置 ====================
# 默认 IP
sed -i 's/192.168.1.1/192.168.2.2/g' package/base-files/files/bin/config_generate

# 修改默认时间格式
sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $(find ./package/*/autocore/files/ -type f -name "index.htm")

# ==================== 追加 .config 配置 ====================
cat >> .config <<EOF

# OpenList 核心 + LuCI
CONFIG_PACKAGE_openlist=y
CONFIG_PACKAGE_luci-app-openlist2=y

# OpenClash 主程序
CONFIG_PACKAGE_luci-app-openclash=y

# 必要依赖
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_kmod-tun=y

# 固件分区大小（内核64MB，RootFS 2048MB）
CONFIG_TARGET_KERNEL_PARTSIZE=64
CONFIG_TARGET_ROOTFS_PARTSIZE=2048

EOF
