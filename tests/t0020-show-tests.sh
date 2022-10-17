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

test_expect_success 'Test "show --stdout --strip-field"' '
	echo "threethree" >expect &&
	"$PASS" show --stdout=3 --strip-field multiline >actual &&
	test_cmp expect actual
'

test_expect_success 'Test "show --stdout --strip-field" with extra colon' '
	echo "pass: word" >expect &&
	echo "field: pass: word" | "$PASS" insert -m extra-colon &&
	"$PASS" show --stdout=1 --strip-field extra-colon >actual &&
	test_cmp expect actual
'

test_expect_success 'Test "show --strip-field" with multiple lines' '
	test_must_fail "$PASS" show --strip-field multiline 2>stderr &&
	grep ".--strip-field. only works on a specific line" stderr
'

test_expect_success 'Test "show --stdout" with out-of-range line-number' '
	test_must_fail "$PASS" show --stdout=42 multiline >actual 2>stderr &&
	test ! -s actual &&
	grep "There is no password at line 42" stderr
'

test_expect_success 'Test "show --stdout=<field>"' '
	echo "third: threethree" >expect &&
	"$PASS" show --stdout=third multiline >actual &&
	test_cmp expect actual
'

test_expect_success 'Test "show --stdout=<field> --strip-field"' '
	echo "fourfour" >expect &&
	"$PASS" show --stdout=fourth --strip-field multiline >actual &&
	test_cmp expect actual
'

test_expect_success 'Test "show --stdout=<field>" with partial match' '
	test_must_fail "$PASS" show --stdout=sec multiline >actual 2>stderr &&
	test ! -s actual &&
	grep "There is no password at line sec" stderr
'

test_expect_success 'Test "show --stdout=<field>" with non-existing field' '
	test_must_fail "$PASS" show --stdout=nope multiline >actual 2>stderr &&
	test ! -s actual &&
	grep "There is no password at line nope" stderr
'

test_expect_success 'Huge password file should not lead to SIGPIPE' '
	echo 42 >expect &&
	seq 1 100000 >content &&
	"$PASS" insert -m huge <content &&
	"$PASS" show --stdout=42 huge >actual 2>err &&
	test_cmp expect actual &&
	test ! -s err
'

test_done
