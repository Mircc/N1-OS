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

# Default IP
sed -i 's/192.168.1.1/192.168.50.200/g' package/base-files/files/bin/config_generate


# Add packages
#添加科学上网源
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth 1 https://github.com/ophub/luci-app-amlogic package/amlogic
#git clone --depth 1 https://github.com/sirpdboy/luci-app-ddns-go package/ddnsgo
git clone --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns
#git clone --depth 1 https://github.com/sbwml/luci-app-alist package/alist
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
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

#删除库中的插件，使用自定义源中的包。
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
#rm -rf feeds/luci/applications/luci-app-ddns-go
#rm -rf feeds/packages/net/ddns-go
#rm -rf feeds/packages/net/alist
#rm -rf feeds/luci/applications/luci-app-alist
#rm -rf feeds/luci/applications/openwrt-passwall

# 替换luci-app-openvpn-server imm源的启动不了服务！
#rm -rf feeds/luci/applications/luci-app-openvpn-server
#git_sparse_clone main https://github.com/kiddin9/kwrt-packages luci-app-openvpn-server
# 调整 openvpn-server 到 VPN 菜单
#sed -i 's/services/vpn/g' package/luci-app-openvpn-server/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/luci-app-openvpn-server/luasrc/model/cbi/openvpn-server/*.lua
#sed -i 's/services/vpn/g' package/luci-app-openvpn-server/luasrc/view/openvpn/*.htm


#替换luci-app-socat为https://github.com/chenmozhijin/luci-app-socat
#rm -rf feeds/luci/applications/luci-app-socat
#git_sparse_clone main https://github.com/chenmozhijin/luci-app-socat luci-app-socat
