#!/bin/bash
# ============ 函数：Git稀疏克隆指定目录 ============
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# ============ 打印 OpenWrt 版本号 ============
if [ -f include/version.mk ]; then
    OPENWRT_VER=$(grep "VERSION_NUMBER:=" include/version.mk | sed 's/.*,//;s/)//;s/ //g')
    echo "=============================================="
    echo " 当前源码 OpenWrt 版本号: $OPENWRT_VER"
    echo " 源码路径: $(pwd)"
    echo "=============================================="
else
    echo "⚠ 未找到 include/version.mk，无法检测版本号"
fi

# ============ 品牌修改为 N1_OS ============
sed -i "s/DISTRIB_ID='ImmortalWrt'/DISTRIB_ID='N1_OS'/g" package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_RELEASE='.*'/DISTRIB_RELEASE='${OPENWRT_VER}'/g" package/base-files/files/etc/openwrt_release
sed -i "s/ImmortalWrt/N1_OS/g" package/base-files/files/etc/banner
sed -i "s/OpenWrt/N1_OS/g" package/base-files/files/etc/banner

LUCI_CFG="feeds/luci/modules/luci-base/root/etc/config/luci"
if [ -f "$LUCI_CFG" ]; then
  sed -i "s/ImmortalWrt/N1_OS/g" "$LUCI_CFG"
  sed -i "s/OpenWrt/N1_OS/g" "$LUCI_CFG"
fi
find feeds/luci/modules/luci-base/po -type f -name "*.po" -exec sed -i "s/ImmortalWrt/N1_OS/g" {} \;
find feeds/luci/modules/luci-base/po -type f -name "*.po" -exec sed -i "s/OpenWrt/N1_OS/g" {} \;
LOGIN_VIEW="feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm"
if [ -f "$LOGIN_VIEW" ]; then
  sed -i 's/ImmortalWrt/N1_OS/g' "$LOGIN_VIEW"
  sed -i 's/OpenWrt/N1_OS/g' "$LOGIN_VIEW"
fi

# ============ 添加常用插件 ============
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/amlogic
git clone --depth=1 https://github.com/sirpdboy/luci-app-ddns-go package/ddnsgo
git clone -b v5-lua --single-branch --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns
git clone -b lua --single-branch --depth 1 https://github.com/sbwml/luci-app-alist package/alist
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

# ============ 添加 luci-app-openlist2 + 核心程序 ============
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2.git package/openlist

# ============ 添加 luci-app-openclash ============
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# ============ 开启插件 + Overlay 大小 ============
cat >> .config <<EOF
# OpenList 核心 + LuCI
CONFIG_PACKAGE_openlist=y
CONFIG_PACKAGE_luci-app-openlist2=y

# OpenClash 主程序
CONFIG_PACKAGE_luci-app-openclash=y

# 常用依赖
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_kmod-tun=y

# 固件分区（内核64MB，RootFS 2048MB）
CONFIG_TARGET_KERNEL_PARTSIZE=64
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
EOF

# ============ 检测版本并切换防火墙 ============
make defconfig >/dev/null 2>&1
if [[ "$OPENWRT_VER" =~ ^24\. || "$OPENWRT_VER" =~ ^23\. || "$OPENWRT_VER" =~ ^22\.03 ]]; then
    sed -i '/CONFIG_PACKAGE_firewall=/d' .config
    echo "CONFIG_PACKAGE_firewall4=y" >> .config
    echo "# CONFIG_PACKAGE_firewall is not set" >> .config
    echo "CONFIG_PACKAGE_kmod-nft-tproxy=y" >> .config
    echo "✅ 已切换到 Firewall4 并启用 kmod-nft-tproxy"
else
    sed -i '/CONFIG_PACKAGE_firewall4=/d' .config
    echo "CONFIG_PACKAGE_firewall=y" >> .config
    echo "CONFIG_PACKAGE_iptables-mod-tproxy=y" >> .config
    echo "✅ 保持 Firewall3 并启用 iptables-mod-tproxy"
fi

# ============ 移除冲突包 ============
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-alist
rm -rf feeds/packages/net/alist

# ============ 修改默认 IP ============
sed -i 's/192.168.1.1/192.168.2.2/g' package/base-files/files/bin/config_generate

# ============ 修改默认时间格式 ============
sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $(find ./package/*/autocore/files/ -type f -name "index.htm")