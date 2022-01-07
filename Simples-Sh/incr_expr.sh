# incr_expr.sh - a simples package for shell arithmetic
# Copyright (c) 2008 J. Greg Davidson.  All rights reserved.

# var_expr VARIABLE EXPR-COMPATIBLE-EXPRESSION
# e.g.: var_expr x '(' $this + $that ')' * $scale
var_expr() {
#   assert_simple_re "$simple_name_re" "$1" 1 var_expr -- "$@"
    var_expr_="$1" ; shift
    simple_set "$var_expr_" `expr "$@"`
}

# var_incr INTEGER_VARIABLE [EXPR-COMPATIBLE-EXPRESSION]
# increment VARIABLE by EXPRESSION or 1
var_incr() {
#   assert_simple_re "$simple_name_re" "$1" 1 var_incr -- "$@"
    var_incr_="$1"; var_incr__=`simple_get $1` ; shift
#   assert_simple_re '[+-]?[0-9][0-9]*" "$1" 1 var_incr -- "$var_incr__" "$@"
#   var_expr "$var_incr_" "$var_incr__" + '(' "${@:1}" ')'
    simple_set "$var_incr_" `expr "$var_incr__" + '(' "${@-1}" ')'`
}

# post_incr INTEGER_VARIABLE -- like var++ in C
post_incr() { simple_get "$1" ; var_incr "$@" ; }

# post_incr INTEGER_VARIABLE -- like ++var in C
pre_incr() { var_incr "$@" ; simple_get "$1" ; }
