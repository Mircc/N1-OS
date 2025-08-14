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

# ============ 获取 OpenWrt 版本号 ============
if [ -f include/version.mk ]; then
    OPENWRT_VER=$(grep -E "VERSION_NUMBER" include/version.mk | sed -E 's/.*:=\s*//;s/[^0-9\.].*//')
    echo "=============================================="
    echo " 当前源码 OpenWrt 版本号: $OPENWRT_VER"
    echo " 源码路径: $(pwd)"
    echo "=============================================="
else
    echo "⚠ 未找到 include/version.mk，无法检测版本号"
    OPENWRT_VER="unknown"
fi

# ============ 品牌修改为 N1_OS ============
sed -i "s|DISTRIB_ID='ImmortalWrt'|DISTRIB_ID='N1_OS'|g" package/base-files/files/etc/openwrt_release
sed -i "s|DISTRIB_RELEASE='.*'|DISTRIB_RELEASE='${OPENWRT_VER}'|g" package/base-files/files/etc/openwrt_release
sed -i "s|ImmortalWrt|N1_OS|g" package/base-files/files/etc/banner
sed -i "s|OpenWrt|N1_OS|g" package/base-files/files/etc/banner

LUCI_CFG="feeds/luci/modules/luci-base/root/etc/config/luci"
[ -f "$LUCI_CFG" ] && {
  sed -i "s|ImmortalWrt|N1_OS|g" "$LUCI_CFG"
  sed -i "s|OpenWrt|N1_OS|g" "$LUCI_CFG"
}

FILES_LIST=$(find feeds/luci/modules/luci-base/po -type f -name "*.po")
[ -n "$FILES_LIST" ] && sed -i "s|ImmortalWrt|N1_OS|g" $FILES_LIST
[ -n "$FILES_LIST" ] && sed -i "s|OpenWrt|N1_OS|g" $FILES_LIST

LOGIN_VIEW="feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm"
[ -f "$LOGIN_VIEW" ] && {
  sed -i 's|ImmortalWrt|N1_OS|g' "$LOGIN_VIEW"
  sed -i 's|OpenWrt|N1_OS|g' "$LOGIN_VIEW"
}

# ============ 添加插件 ============
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/amlogic
git clone --depth=1 https://github.com/sirpdboy/luci-app-ddns-go package/ddnsgo
git clone -b v5-lua --single-branch --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns
git clone -b lua --single-branch --depth 1 https://github.com/sbwml/luci-app-alist package/alist
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky
git clone --depth=1 https://github.com/sbwml/luci-app-openlist2.git package/openlist
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# ============ 配置编译选项 ============
cat >> .config <<EOF
CONFIG_PACKAGE_openlist=y
CONFIG_PACKAGE_luci-app-openlist2=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_TARGET_KERNEL_PARTSIZE=64
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
EOF

# 防火墙判断
if [[ "$OPENWRT_VER" =~ ^24\. || "$OPENWRT_VER" =~ ^23\. || "$OPENWRT_VER" =~ ^22\.03 ]]; then
    echo "✅ 检测到 OpenWrt $OPENWRT_VER - 启用 Firewall4（nftables）"
    sed -i '/CONFIG_PACKAGE_firewall=/d' .config
    echo "CONFIG_PACKAGE_firewall4=y" >> .config
    echo "# CONFIG_PACKAGE_firewall is not set" >> .config
    echo "CONFIG_PACKAGE_kmod-nft-tproxy=y" >> .config
else
    echo "⚠ 检测到 OpenWrt $OPENWRT_VER - 使用 Firewall3（iptables）"
    sed -i '/CONFIG_PACKAGE_firewall4=/d' .config
    echo "CONFIG_PACKAGE_firewall=y" >> .config
    echo "CONFIG_PACKAGE_iptables-mod-tproxy=y" >> .config
fi

# ============ 移除冲突包 ============
rm -rf feeds/packages/net/v2ray-geodata \
       feeds/luci/themes/luci-theme-argon \
       feeds/luci/applications/luci-app-argon-config \
       feeds/packages/net/mosdns \
       feeds/packages/utils/v2dat \
       feeds/luci/applications/luci-app-mosdns \
       feeds/luci/applications/luci-app-alist \
       feeds/packages/net/alist

# ============ 修改默认 IP ============
sed -i 's/192.168.1.1/192.168.50.200/g' package/base-files/files/bin/config_generate

# ============ 修改默认时间格式 ============
TIME_FILES=$(find ./package/*/autocore/files/ -type f -name "index.htm")
[ -n "$TIME_FILES" ] && sed -i 's|os.date()|os.date("%Y-%m-%d %H:%M:%S %A")|g' $TIME_FILES
