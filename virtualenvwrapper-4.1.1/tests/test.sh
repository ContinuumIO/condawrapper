# -*- mode: shell-script -*-

test_dir=$(cd $(dirname $0) && pwd)
source "$test_dir/setup.sh"

oneTimeSetUp() {
    rm -rf "$WORKON_HOME"
    mkdir -p "$WORKON_HOME"
    source "$test_dir/../virtualenvwrapper.sh"
}

oneTimeTearDown() {
    rm -rf "$WORKON_HOME"
}

setUp () {
    echo
    unset VIRTUALENVWRAPPER_INITIALIZED
    rm -f "$TMPDIR/catch_output"
}

test_virtualenvwrapper_initialize() {
    assertTrue "Initialized" virtualenvwrapper_initialize
    for hook in premkvirtualenv postmkvirtualenv prermvirtualenv postrmvirtualenv preactivate postactivate predeactivate postdeactivate
    do
        assertTrue "Global $WORKON_HOME/$hook was not created" "[ -f $WORKON_HOME/$hook ]"
        assertTrue "Global $WORKON_HOME/$hook is not executable" "[ -x $WORKON_HOME/$hook ]"
    done
    echo "echo GLOBAL initialize >> \"$TMPDIR/catch_output\"" >> "$WORKON_HOME/initialize"
    virtualenvwrapper_initialize
    output=$(cat "$TMPDIR/catch_output")
    expected="GLOBAL initialize"
    assertSame "$expected" "$output"
}

test_virtualenvwrapper_space_in_workon_home() {
    before="$WORKON_HOME"
    export WORKON_HOME="$WORKON_HOME/this has spaces"
 	expected="$WORKON_HOME"
    mkdir -p "$expected"
    virtualenvwrapper_initialize
    RC=$?
    assertSame "$expected" "$WORKON_HOME"
    assertSame "0" "$RC"
    export WORKON_HOME="$before"
}

test_virtualenvwrapper_verify_workon_home() {
    assertTrue "WORKON_HOME not verified" virtualenvwrapper_verify_workon_home
}

test_virtualenvwrapper_verify_workon_home_missing_dir() {
    old_home="$WORKON_HOME"
    WORKON_HOME="$WORKON_HOME/not_there"
    assertTrue "Directory already exists" "[ ! -d \"$WORKON_HOME\" ]"
    virtualenvwrapper_verify_workon_home >"$old_home/output" 2>&1
    output=$(cat "$old_home/output")
    assertSame "NOTE: Virtual environments directory $WORKON_HOME does not exist. Creating..." "$output"
    WORKON_HOME="$old_home"
}

test_virtualenvwrapper_verify_workon_home_missing_dir_quiet() {
    old_home="$WORKON_HOME"
    WORKON_HOME="$WORKON_HOME/not_there_quiet"
    assertTrue "Directory already exists" "[ ! -d \"$WORKON_HOME\" ]"
    output=$(virtualenvwrapper_verify_workon_home -q 2>&1)
    assertSame "" "$output"
    WORKON_HOME="$old_home"
}

test_virtualenvwrapper_verify_workon_home_missing_dir_grep_options() {
    old_home="$WORKON_HOME"
    WORKON_HOME="$WORKON_HOME/not_there"
    # This should prevent the message from being found if it isn't
    # unset correctly.
    export GREP_OPTIONS="--count"
    assertTrue "WORKON_HOME not verified" virtualenvwrapper_verify_workon_home
    WORKON_HOME="$old_home"
    unset GREP_OPTIONS
}

test_python_interpreter_set_incorrectly() {
    return_to="$(pwd)"
    cd "$WORKON_HOME"
    mkvirtualenv no_wrappers >/dev/null 2>&1
	RC=$?
	assertEquals "mkvirtualenv return code wrong" "0" "$RC"
    expected="No module named virtualenvwrapper"
    # test_shell is set by tests/run_tests
    if [ "$test_shell" = "" ]
    then
        export test_shell=$SHELL
    fi
    outfilename="$WORKON_HOME/test_out.$$"
    subshell_output=$(VIRTUALENVWRAPPER_PYTHON="$WORKON_HOME/no_wrappers/bin/python" $test_shell $return_to/virtualenvwrapper.sh >"$outfilename" 2>&1)
    #echo "$subshell_output"
    cat "$outfilename" | sed "s/'//g" | grep -q "$expected" 2>&1
    found_it=$?
    #echo "$found_it"
    assertTrue "Expected \'$expected\', got: \'$(cat "$outfilename")\'" "[ $found_it -eq 0 ]"
    assertFalse "Failed to detect invalid Python location" "VIRTUALENVWRAPPER_PYTHON=$VIRTUAL_ENV/bin/python virtualenvwrapper_run_hook initialize >/dev/null 2>&1"
    cd "$return_to"
    deactivate
}

test_virtualenvwrapper_verify_virtualenv(){
    assertTrue "Verified unable to verify virtualenv" virtualenvwrapper_verify_virtualenv

    VIRTUALENVWRAPPER_VIRTUALENV="thiscannotpossiblyexist123"
    assertFalse "Incorrectly verified virtualenv" virtualenvwrapper_verify_virtualenv
}

test_virtualenvwrapper_verify_virtualenv_clone(){
    assertTrue "Verified unable to verify virtualenv_clone" virtualenvwrapper_verify_virtualenv_clone

    VIRTUALENVWRAPPER_VIRTUALENV_CLONE="thiscannotpossiblyexist123"
    assertFalse "Incorrectly verified virtualenv_clone" virtualenvwrapper_verify_virtualenv_clone
}

. "$test_dir/shunit2"
