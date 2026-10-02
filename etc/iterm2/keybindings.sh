#!/bin/sh
# iTerm2 メニューショートカットの上書き (反映には iTerm2 の再起動が必要)
# HHKB(JIS) の ⌘+ は ⌘; として届くため、文字拡大を ⌘; に割り当てる
# 本体キーボードの ⌘= / ⌘+ は Karabiner ルールで ⌘; に変換している
defaults write com.googlecode.iterm2 NSUserKeyEquivalents -dict-add \
    "Make Text Bigger" '@;' \
    "Open Autocomplete" '@~;'
