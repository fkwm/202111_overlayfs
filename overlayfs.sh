#!/bin/bash
#
# **********************************************************************
#
#                              License
#
#                   These codes are licensed under CC0.
#  [English]  https://creativecommons.org/publicdomain/zero/1.0/deed.en
#  [Japanese] https://creativecommons.org/publicdomain/zero/1.0/deed.ja
#
# **********************************************************************
#
# ChangeLogs
#
# 2020-10-01
#   * _has_opt() 及び _has_opt_value() を追加
#
# 2020-06-24
#   * VERBOSE について boolean型から元に戻した(動作が意図どおりにならないため)
#   * デフォルト(何もしていない状態)の動作を ls から echo test とした(ls だと長すぎる場合がある)
#
# 2019-05-28
#   * VERBOSE や _message の引数に boolean型を採用
#   * _message の引数の順序等を変更
#
# 2019-03-18
#   * set -eu のうち -e を廃止
#   * 上に代り onerror() を導入
#
# 2019-02-01
#   * _get_yes_no に OPT_ASSUME_YES 対応を追加
#
# 2019-01-22
#   * set -eu の設定を追加
#
# 2019-01-08
#   * [fix] _message の出力書式を変更
#
# 2018-11-16
#   * [tools] _has_string 追加
#
# 2018-11-08
#   * [tools] _assert_command 追加
#   * [tools] _has_command 追加
#
# 2018-11-01
#   * [tools] _add_text_to_file 追加
#   * コメントを多少修正
#

# ====================================================================
#   Base Variable
# ====================================================================

set -u
# strict 設定
#   特に $1 等の引数については注意すること → _check_help() の書き方を参照
#   ( $1 を ${1:-} としている )
#     参考例 「シェルスクリプトを書くときはset -euしておく - Qiita」
#            https://qiita.com/youcune/items/fcfb4ad3d7c1edf9dc96


SCRIPT_NAME=`basename $0`
SCRIPT_DIR=`cd \`dirname $0\`; pwd`
SCRIPT_FULLNAME="$SCRIPT_DIR/$SCRIPT_NAME"
PWD=`pwd`

# ====================================================================
#   User Configuration
# ====================================================================

# ====================================================================
#   System Variable
# ====================================================================
DEBUG=
VERBOSE=
CMD_PING=/bin/ping # _check_nw_with_ping が使用します
CMD_WHICH=/usr/bin/which
CMD_RASPI_CONFIG=`which raspi-config`

# もしこのスクリプトがシンボリックリンク先により実行されている
# 場合は設定されます。
SCRIPT_ORIGIN_NAME=
SCRIPT_ORIGIN_DIR=
SCRIPT_ORIGIN_FULL_NAME=



OPT_CMD=
OPT_ASSUME_YES=

# ====================================================================
#   Local functions
# ====================================================================
init() {
  # この関数は _init() から呼ばれます。
  # TODO: 初期化時に設定する項目を記入してください
  :
}

is_overlay_enabled() {
  grep -q "boot=overlay" /proc/cmdline
}

# ----------------------------------------------------------------------
#   Template Functions
# ----------------------------------------------------------------------
_init () {
  _init_script_origin_full_name
  init
}

_read_args() {
  _check_help "$@"
  _read_getopts "$@"

  # TODO: オプション以外の引数を受け取る場合は以下をコメントアウトして編集してください
  shift `expr $OPTIND - 1`
  OPT_CMD=${1:-}

  if [ x$OPT_CMD = x ]; then
    OPT_CMD="list"
  fi




}

_read_config() {
  # 設定ファイルを読み込みます
  # (デフォルトではこの関数は呼び出されません)
  if [ -r $CONFIG_FILE ];then
     . $CONFIG_FILE
  else
     _message "$CONFIG_FILE が見つかりません" "Warning" true true
  fi
}



_init_script_origin_full_name() {
  if [ -L $SCRIPT_FULLNAME ]; then
      path=`readlink -f $SCRIPT_FULLNAME`
      SCRIPT_ORIGIN_DIR=`dirname $path`
      SCRIPT_ORIGIN_NAME=`basename $path`
      SCRIPT_ORIGIN_FULL_NAME=$SCRIPT_ORIGIN_DIR/$SCRIPT_ORIGIN_NAME
  fi
}

_check_help() {
  if [ x"${1:-}" = "x--help" -o x"${1:-}" = "x--version" ]; then
    _echo_help 1>&2;
    exit 0;
  fi
}

_check_args() {
  # TODO: 引数のエラーチェックを記入してください
  # _assert_variable VAR "VAR の設定が必要です。"
  # [ -r "$VAR" ] || _error "VAR を読み込むことができません"
  :
}

_read_getopts() {
  # TODO: 以下にこのコマンドが受けとるオプションを構成してください
  while getopts hvdy OPT
    do
      case $OPT in
        h) _echo_help 1>&2 ;
           exit 0;;
        v) VERBOSE=true ;;
        d) DEBUG=echo ;;
        y) OPT_ASSUME_YES=1 ;;
      esac
    done
}


_echo_message() {
  message="$1"
  echo -e "\n$message\n"

}

_echo_help () {
  # TODO: 以下にこのコマンドのヘルプを構成してください
cat <<EOF

Wrapped command of raspi-config which has BUG for get_overlay_now.
This command enable or disable OverlayFS
With using 'raspi-config nonint enable_overlayfs' for enable or 'raspi-config nonint disable_overlayfs' for disable.
And fixin the bug of get_overlay_now

USAGE : $SCRIPT_NAME [OPTIONS] [enable|disable]

COMMAND:
    if omitted , this command executes 'list'.
    enable  ... (can be reduced to 'e') enable OverlayFS  ( execute raspi-config nonint enable_overlayfs )
    disable ... (can be reduced to 'd') disable  OverlayFS  ( execute raspi-config nonint disable_overlayfs )
    list ... (can be reduced to 'l') print status

OPTIONS:

    -h  print this message
    -v  print info
    -d  enable debug mode (set \$DEBUG=echo )
    -y assume yes, no prompt.

===== Japanese help ======

Raspberry Pi OS の raspi-config をラップしたコマンドであり、OverlayFS の有効/無効を切り替えます。
raspi-config nonint enable_overlayfs や raspi-config nonint disable_overlayfs をラップし、raspi-config nonint get_overlay_now のバグに対応します。

USAGE : $SCRIPT_NAME [OPTIONS] [enable|disable]

COMMAND:

    コマンドが未設定の場合はlistが実行されます
    enable  ... ('e'と省略可能) OverlayFS を有効にします。( raspi-config nonint enable_overlayfs を実行します)
    disable ... ('d'と省略可能) OverlayFS を無効にします。( raspi-config nonint disable_overlayfs を実行します)
    list ...  ('l'と省略可能) 状態を表示します

OPTIONS:

    -h  このメッセージを表示します
    -v  情報を標準エラー出力に表示します
    -d  デバッグ用(\$DEBUG=echoを設定します)
    -y  確認表示をせずに yes として処理します

EOF
}

_error() {
  _message "" "Error" true
  _message "[Error] ${@}" "Error" true
  echo -e "\ndetails, please see '$SCRIPT_NAME --help'\n"
  exit 1;
}

_info() {
  # 情報を表示するには $VERBOSE が設定されている必要があります
  if _is_verbose_mode; then
    _message "${@}" "Info" true true
  fi
  return 0
}

_verbose() {
  # _info のエイリアス
  _info "${@}"
  return 0
}

_debug() {
  # $DEBUG が指定されているとき 引数で与えられた情報を標準エラー出力に表示します
  if _is_debug_mode; then
      _message "${@}" "Debug" false true
  fi
  return 0
}

_message() {
  local contents=$1
  local label=$2 # $use_header が設定されている場合のみ有効となります
  local is_error_output=${3:-false}  # 標準出力ではなくエラー出力を使用するか
  local use_header=${4:-false}       # 時刻等ヘッダを追加するか
  local header=

  if $use_header; then
      header="[$SCRIPT_NAME][$label][`date \"+%F %H:%M:%S\"`]"
  fi

  if $is_error_output; then
    echo "$header$contents" 1>&2
  else
    echo "$header$contents"
  fi

  return 0

}

_assert_variable() {
  # 変数を評価(assert)します。変数の内容が空の場合はエラーを表示して終了します。
  # $1 ... variable name like HOGE for $HOGE
  # $2 ... error message
  #
  # 使用例) _assert_variable "VAR1" "変数 VAR1 が設定されていません"
  local variable_name=$1
  eval export variable_value=\${$1:-}

  if [ "x$variable_value" = "x" ]; then
     shift 1
     _error "$*"
  fi
}


_assert_command() {
  # コマンドを評価(assert)します。コマンドが存在しない場合はエラーを表示して終了します。
  # [引数]
  # $1 ... コマンド名を指定します
  # $2 ... エラーメッセージとなります
  # [戻り値]
  # 0 ... コマンドが存在します
  # 上以外 ... コマンドが存在しません
  #
  # 使用例) _assert_command "mkdir" "このコマンドには mkdir が必要です"



  local command_name=$1
  if ! _has_command $command_name; then
      shift 1
      _error "$*"
  fi

}

_is_debug_mode() {
  # デバッグモードか確認します(デフォルトでは -d が指定された場合)
  # 使用例) if _is_debug_mode; then ....
  # 使用例) _is_debug_mode && echo debug mode ..

  if [ "x$DEBUG" = x ]; then
      return 1
  else
      return 0
  fi
}

_is_verbose_mode() {
  # 冗長(verbose)モードか確認します(デフォルトでは -d が指定された場合)

  if [ "x$VERBOSE" = x ]; then
      return 1
  else
      return 0
  fi
}

_is_not_debug_mode() {
  # デバッグモードでないことを確認します
  ! _is_debug_mode
}

_get_yes_no () {
  # yes no プロンプトを出します
  # 使用例) if _get_yes_no "Are you sure ? [yes/no] " ; then...
  # * $OPT_ASSUME_YES が設定されている場合は正常終了します
  if [ ${OPT_ASSUME_YES:-} ]; then
    return 0
  fi

  local _ANSWER=
  if [ $# -eq 0 ]; then
    echo "Usage: GetYesNo message" 1>&2
    exit 1
  fi
  while :
  do
    if [ "`echo -n`" = "-n" ]; then
      echo "$@ \c"
    else
      echo -n "$@ "
    fi

    read _ANSWER
    case "$_ANSWER" in
      [yY] | yes | YES | yes ) return 0 ;;
      [nN] | no  | NO  | no  ) return 1 ;;
      * ) echo "Please enter y or n."   ;;
    esac
  done
}


_is_mount() {
  # マウントしているか確認します
  # 使用例) if _is_mount /mnt/test; then ...

  local mountpoint=$1

  if [ x$mountpoint != x ]; then
    if `mount | grep "$mountpoint" >/dev/null 2>&1`; then
        return 0
    fi
  fi

  return 1
}

_add_text_to_file() {
  # ファイルに文字列を書き込みます
  # 主にDEBUGコマンドを併用するために使用します
  # 使用例) add_text_to_file "追加するテキスト" path/to/file
  # 使用例) $DEBUG add_text_to_file "追加するテキスト" path/to/file
  local file=$1
  local contents="$2"
  echo "$contents" >> $file
}

_has_command() {
  # 引数で与えられたコマンド名が存在すれば 0 を返します
  # 使用例) if _has_command test_command; then ....; fi
  # 注意) 内部で which を使用しています。echoのようなbuilt-in関数を引数にできません。

  local command_name=$1
  if `which $command_name >/dev/null 2>&1`; then
      return 0
  else
      return 1
  fi

}

_has_string() {
  # Usage _has_command $target $search
  # $target の中に $search があれば 0 を返します (大文字小文字は区別しません)
  # 使用例) if _has_string "test of function" "test"; then ....; fi

  local string="$1"
  local needle="$2"

  if `echo "$string" | grep -i $needle >/dev/null 2>&1`; then
     return 0
  else
     return 1
  fi

}

_check_nw_with_ping() {
  # Usage _check_nw_with_ping <ip_address>
  # <ip_address>へのpingが成功
  # 使用例) if __check_nw_with_ping 192.168.1.1 ; then echo "success"; fi

  local ip_address=$1
  $CMD_PING $ip_address -c 1 >> /dev/null
  return $?
}

_has_opt() {
  local value=${1:-false}

  case "$value" in
      [yY] | yes | YES | Yes | [tT] | true | TRUE | True ) return 0 ;;
      * ) return 1;;
  esac
}

_has_opt_value() {
  local name=${1:-}
  if [ $name ]; then
    return 0
  else
    return 1
  fi
}

# ----------------------------------------------------------------------
# from 「エラー監視時(set -e)の汎用トラップコード(trap) - Qiita」
#        https://qiita.com/kobake@github/items/8d14f42ef5f36d4b80e4
#
# * begintrap は関数の中であれば関数の中に置く必要があります
#
# ----------------------------------------------------------------------


onerror()
{
    local status=$?
    local script=$0
    local line=$1
    shift

    local args=
    for i in "$@"; do
        args+="\"$i\" "
    done

    echo ""
    echo "------------------------------------------------------------"
    echo "Error occured on $script [Line $line]: Status $status"
    echo ""
    echo "PID: $$"
    echo "User: $USER"
    echo "Current directory: $PWD"
    echo "Command line: $script $args"
    echo "------------------------------------------------------------"
    echo ""
}

begintrap()
{
    set -e
    trap 'onerror $LINENO "$@"' ERR
}

endtrap()
{
    set +e
}


# ====================================================================
#   main
# ====================================================================

_init "$@"
_read_args "$@"
_check_args

# 以下は実行例です

if [ x$OPT_CMD = xlist -o x$OPT_CMD = xl ]; then
  # if grep -q "boot=overlay" /proc/cmdline; then
  if is_overlay_enabled; then
    _echo_message "OvelayFS is enabled. (ROM mode)"
  else
    _echo_message "OvelayFS is *NOT* enabled. (No ROM mode)"
  fi
elif  [ x$OPT_CMD = xenable -o x$OPT_CMD = xe ]; then
  if is_overlay_enabled; then
    _error "Overlay Already Enabled."
  else
    if _get_yes_no "Do you enable OverlayFS ?" ; then
      $DEBUG $CMD_RASPI_CONFIG nonint enable_overlayfs
      _echo_message "*** Reboot required to apply settings. ***"
    else
      _echo_message "Canceled."
    fi
  fi
elif  [ x$OPT_CMD = xdisable -o x$OPT_CMD = xd ]; then
  if ! is_overlay_enabled; then
    _error "Overlay Already Disabled."
  else
    if _get_yes_no "Do you disable OverlayFS ?" ; then
      $DEBUG $CMD_RASPI_CONFIG nonint disable_overlayfs
      _echo_message "*** Reboot required to apply settings. ***"
    else
      _echo_message "Canceled."
    fi
  fi
else
  _error "Can't recognize COMMAND. You must put any of {list|enable|disable}"
fi
