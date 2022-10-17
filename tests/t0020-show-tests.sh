#!/usr/bin/env bash

test_description='Test show'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'Test "show" command' '
	"$PASS" init $KEY1 &&
	"$PASS" generate cred1 20 &&
	"$PASS" show cred1
'

test_expect_success 'Test "show" command with spaces' '
	"$PASS" insert -e "I am a cred with lots of spaces"<<<"BLAH!!" &&
	[[ $("$PASS" show "I am a cred with lots of spaces") == "BLAH!!" ]]
'

test_expect_success 'Test "show" command with unicode' '
	"$PASS" generate 🏠 &&
	"$PASS" show | grep -q '🏠'
'

test_expect_success 'Test "show" of nonexistant password' '
	test_must_fail "$PASS" show cred2
'

test_expect_success 'Test "show" command with multiline password' '
	cat >content <<-\EOF &&
	p4$$w0rd
	second: twotwo
	third: threethree
	fourth: fourfour
	EOF
	"$PASS" insert -m multiline <content &&
	"$PASS" show multiline >actual &&
	test_cmp content actual
'

test_expect_success 'Test "show --stdout"' '
	echo "second: twotwo" >expect &&
	"$PASS" show --stdout=2 multiline >actual &&
	test_cmp expect actual
'

test_expect_success 'Test "show --stdout" with out-of-range line-number' '
	test_must_fail "$PASS" show --stdout=42 multiline 2>stderr &&
	grep "There is no password at line 42" stderr
'

test_expect_success 'Huge password file should not lead to SIGPIPE' '
	echo PaSSWoRD >expect &&
	cat expect >content &&
	seq 2 100000 >>content &&
	"$PASS" insert -m huge <content &&
	"$PASS" show --stdout=1 huge >actual &&
	test_cmp expect actual
'

test_done
