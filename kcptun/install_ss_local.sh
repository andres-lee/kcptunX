#!/bin/sh

#  install_ss_local.sh
#  ShadowsocksX-NG
#
#  Created by 邱宇舟 on 16/6/6.
#  Copyright © 2016年 qiuyuzhou. All rights reserved.


cd `dirname "${BASH_SOURCE[0]}"`
mkdir -p "$HOME/Library/Application Support/kcptun/kcptun-20160725"
cp -f kcptun "$HOME/Library/Application Support/kcptun/kcptun-20160725/"
rm -f "$HOME/Library/Application Support/kcptun/kcptun"
ln -s "$HOME/Library/Application Support/kcptun/kcptun-20160725/kcptun" "$HOME/Library/Application Support/kcptun/kcptun"

# cp -f libcrypto.1.0.0.dylib "$HOME/Library/Application Support/kcptun/"

echo done