#!/bin/sh

test_description='verbose commit template'
. ./test-lib.sh

write_script check-for-diff <<-'EOF'
	exec grep '^diff --git' "$1"
EOF

write_script check-for-no-diff <<-EOF
	exec grep -v '^diff --git' "\$1"
EOF

cat >message <<'EOF'
subject

body
EOF

test_expect_success 'setup' '
	echo content >file &&
	git add file &&
	git commit -F message
'

test_expect_success 'initial commit shows verbose diff' '
	test_set_editor "$PWD/check-for-diff" &&
	git commit --amend -v
'

test_expect_success 'second commit' '
	echo content modified >file &&
	git add file &&
	git commit -F message
'

check_message() {
	git log -1 --pretty=format:%s%n%n%b >actual &&
	test_cmp "$1" actual
}

test_expect_success 'verbose diff is stripped out' '
	test_set_editor "$PWD/check-for-diff" &&
	git commit --amend -v &&
	check_message message
'

test_expect_success 'verbose diff is stripped out (mnemonicprefix)' '
	test_set_editor "$PWD/check-for-diff" &&
	test_config diff.mnemonicprefix true &&
	git commit --amend -v &&
	check_message message
'

test_expect_success 'commit shows verbose diff with commit.verbose true' '
	echo morecontent >>file &&
	git add file &&
	test_config commit.verbose true &&
	test_set_editor "$PWD/check-for-diff" &&
	git commit --amend
'

test_expect_success 'commit --verbose overrides commit.verbose false' '
	echo evenmorecontent >>file &&
	git add file &&
	test_config commit.verbose false  &&
	test_set_editor "$PWD/check-for-diff" &&
	git commit --amend --verbose
'

test_expect_success 'commit does not show verbose diff with commit.verbose false' '
	echo evenmorecontent >>file &&
	git add file &&
	test_config commit.verbose false &&
	test_set_editor "$PWD/check-for-no-diff" &&
	git commit --amend
'

test_expect_success 'commit --no-verbose overrides commit.verbose true' '
	echo evenmorecontent >>file &&
	git add file &&
	test_config commit.verbose true &&
	test_set_editor "$PWD/check-for-no-diff" &&
	git commit --amend --no-verbose
'

cat >diff <<'EOF'
This is an example commit message that contains a diff.

diff --git c/file i/file
new file mode 100644
index 0000000..f95c11d
--- /dev/null
+++ i/file
@@ -0,0 +1 @@
+this is some content
EOF

test_expect_success 'diff in message is retained without -v' '
	git commit --amend -F diff &&
	check_message diff
'

test_expect_success 'diff in message is retained with -v' '
	git commit --amend -F diff -v &&
	check_message diff
'

test_expect_success 'submodule log is stripped out too with -v' '
	test_config diff.submodule log &&
	git submodule add ./. sub &&
	git commit -m "sub added" &&
	(
		cd sub &&
		echo "more" >>file &&
		git commit -a -m "submodule commit"
	) &&
	test_set_editor cat &&
	test_must_fail git commit -a -v 2>err &&
	test_i18ngrep "Aborting commit due to empty commit message." err
'

test_expect_success 'verbose diff is stripped out with set core.commentChar' '
	test_set_editor cat &&
	test_must_fail git -c core.commentchar=";" commit -a -v 2>err &&
	test_i18ngrep "Aborting commit due to empty commit message." err
'

test_done
