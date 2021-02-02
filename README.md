```
               ███████           ██       ██
              ░██░░░░██         ░██      ░██           █████
              ░██    ░██  █████ ░██      ░██  ██████  ██░░░██
              ░██    ░██ ██░░░██░██████  ░██ ██░░░░██░██  ░██
              ░██    ░██░███████░██░░░██ ░██░██   ░██░░██████
              ░██    ██ ░██░░░░ ░██  ░██ ░██░██   ░██ ░░░░░██
              ░███████  ░░██████░██████  ███░░██████   █████

```

Log debug information from script and commandline to file, to use with tail

<img alt="deblog sample" src="https://github.com/Termplexed/res/blob/master/img/deblog-sample-01.png" />

1. source or add the `deblog.vim` file in a directory where it is sourced at startup
2. Call the various functions by: `g:Deblog2.<FUN>(args)`

You can add commands by calling boot in a script of your choosing:

```vim
for c in g:Deblog2.boot() | exe c | endfor
```

This adds the following commands that can be used in script for easier and cleaner logging:

* DUMP  : Dump anything
* LLOG  : Log with time, file and line information
    * LLOG2, LLOG3 and LLOG4 are have same effect, but as each command can be silenced one can turn logging on / off for selected information.
* LOG   : Plain logging
* QLOG  : Quoted plain logging
* EXLOG : Log result of executing

## Example

In script one want to log 

```vim
" Load all log commands
for c in g:Deblog2.boot() | exe c | endfor
LLOG "Loaded Deblog functions"

fun! s:bar(a1, a2)
	" log arguments
	LLOG "with: " . string(a:)
endfun

LLOG "Creating the dict s:foo"
" A sample dict
let s:foo = {
	\ 'some': 3.14,
	\ 'things': "hello",
	\ 'and': 113.14,
	\ 'can': v:false,
	\ 'canz': v:true,
	\ 'other': [1, 2, 3],
	\ 'what': function('s:bar'),
	\ 'void': v:null,
	\ }

LLOG "Dumping it ..."
" Dump the object s:foo
DUMP s:foo

LLOG "Calling s:bar()"
" Call function which is logging
call s:bar([22, 42], '3ez')

QLOG "I am Quote logged"
call g:Deblog2.spew('Bye Bye!')

```

Result:

<img alt="Code sample result" src="https://raw.githubusercontent.com/Termplexed/res/master/img/deblog-sample-03.png" />


## Environment

If you want to log local script variables etc. by command, the *"Load all log commands"* have to be done in *that* script file!

The commands can also be executed fomr commandline, e.g:

    :DUMP s:


## View log

Typically do `tail -f log_file`. Log file defaults to [`$HOME/.vim/my_deblog.log`](https://github.com/Termplexed/deblog/blob/41057a42e0b1e6cd2fd407c646c1adf40bd911f4/plugin/deblog.vim#L72)

Optionally do `:DEBLOGSHELLTAIL` from vim to open a predefined shell.

Look at [s:shells](https://github.com/Termplexed/deblog/blob/41057a42e0b1e6cd2fd407c646c1adf40bd911f4/plugin/deblog.vim#L43) for specifications.

Selected shell is set at load time to `g:Deblog.shell`  and defaults to [`xterm`](https://github.com/Termplexed/deblog/blob/41057a42e0b1e6cd2fd407c646c1adf40bd911f4/plugin/deblog.vim#L78)







