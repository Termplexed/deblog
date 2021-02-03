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

* Show execution time from last entry
* Accumulated execution time *(Not excluding the rather heavy overhead from deblog)*
* File
* Absolute linenumber of call
* Calling function (if any)
* Can dump objects

### TOC

* [Basic intro](#basic-intro)
* [Example](#example)
* [Environment](#environment)
* [View log and other commands](#view-log---and-other-commands)
* [The boot function](#the-boot-function)
* [Using calls](#using-calls)

<img alt="deblog sample" src="https://github.com/Termplexed/res/blob/master/img/deblog-sample-01.png" />

## Basic intro

1. source or add the `deblog.vim` file in a directory where it is sourced at startup

2. In target script: add `command`s by calling boot in a script of your choosing:

```vim
for c in g:Deblog2.boot() | exe c | endfor
```

***NB! Due to scopes this has to be done in the file you want to access/log local script variables.*** This goes fro the *commands*, `call`s can be done with local script variables from any file, but wil not include file, linenumber etc.

Globals, strings etc. can be logged form anywhere.

This adds [the following commands](https://github.com/Termplexed/deblog/blob/d63b8fb85ef3b73823c6705d5e002287421cef90/plugin/deblog.vim#L541) that can be used in script for easy and clean logging:

* `DUMP`  : Dump anything
    * `DUMP "Some objects: ", s:my_obja, s:other_obj`
    * `DUMP s:foo`
* `LLOG`  : Log with time, file and line information
    * `LLOG "The ID=" . string(s:foo.id)`
* `LLOG2`, `LLOG3` and `LLOG4` : same as `LLOG`, but as each command can be silenced one can turn logging on / off for selected information.
* `LOG`   : Plain logging. Does not log filename, linenumber, function, ...
    * `LOG "Hello"`
* `QLOG`  : Quoted plain logging. Same as `LOG` but output is wrapped in quotes.
    * `QLOG "Hello"`
* `EXLOG` : Log result of executing
    * `EXLOG reltime()`
    * `EXLOG :messages`
    * `EXLOG :verbose function`
    
* *Other commands: [see bottom of page](#view-log---and-other-commands)*

The various functions can also be called by `:call g:Deblog2. ....`, look at the source and / or the [call section](#using-calls). Notable functions:

* [`.spew(msg)`](https://github.com/Termplexed/deblog/blob/d63b8fb85ef3b73823c6705d5e002287421cef90/plugin/deblog.vim#L147)
* [`.objdump(name, obj)`](https://github.com/Termplexed/deblog/blob/d63b8fb85ef3b73823c6705d5e002287421cef90/plugin/deblog.vim#L208)

[<sup>TOC</sup>](#toc)

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

1. Column one show time passed since last log entry. 
2. Column two show the time accumulated since last time reset (header). The time resets if there is more then [`htime`](https://github.com/Termplexed/deblog/blob/e0c02d6be444dcd6aa582ffefbce72eb7b17363e/plugin/deblog.vim#L74) seconds since last call to print. Defaults to 0.5sec if Vim has reltime, else 1sec.

[<sup>TOC</sup>](#toc)

## Environment

If you want to log local script variables etc. *by command*, the *"Load all log commands"* have to be done in *that* script file!

The commands can also be executed from commandline, e.g:

    :DUMP s:

will dump the script environment from where the `command`s was defined.

[<sup>TOC</sup>](#toc)

## View log - and other commands

Typically do `tail -f log_file`. Log file defaults to [`$HOME/.vim/my_deblog.log`](https://github.com/Termplexed/deblog/blob/d63b8fb85ef3b73823c6705d5e002287421cef90/plugin/deblog.vim#L72)

Optionally do `:DEBLOGSHELLTAIL` from vim to open a predefined shell.

Look at [`s:shells`](https://github.com/Termplexed/deblog/blob/d63b8fb85ef3b73823c6705d5e002287421cef90/plugin/deblog.vim#L43) for specifications.

Selected shell is set at load time to `g:Deblog.cmd_shell`  and defaults to [`uxterm`](https://github.com/Termplexed/deblog/blob/d63b8fb85ef3b73823c6705d5e002287421cef90/plugin/deblog.vim#L78). Modify to meet your needs.

Ampersand [is added](https://github.com/Termplexed/deblog/blob/e0c02d6be444dcd6aa582ffefbce72eb7b17363e/plugin/deblog.vim#L389) on execution.

The placeholders `#FILE#` and `#NTAIL#` are replaced with the name of the log-file and number of potentionally existing lines to show on start:

```vim
'uxterm -geometry 85x90-0+0 -T "Deblog #FILE#" -e "tail #NTAIL# -f #FILE#"'
```

With [`ntail`](https://github.com/Termplexed/deblog/blob/e0c02d6be444dcd6aa582ffefbce72eb7b17363e/plugin/deblog.vim#L79) set to 20 and `file` set to `/home/foo/.vim/my_deblog.log` result in:

```vim
'uxterm -geometry 85x90-0+0 -T "Deblog /home/foo/.vim/my_deblog.log" -e "tail 20 -f /home/foo/.vim/my_deblog.log" &'
```

Other commands:

* `DEBMUTE` : Stop writing to log file
* `DEBUNMUTE` : Resume logging

[<sup>TOC</sup>](#toc)

## The boot function

The `g:Deblog.boot([COMMANDS])` function return a list of pre-defined command definitions that can be executed.

Optionally one can add a list as an argument with  selected commands one want to get. E.g. `["LLOG", "DUMP"]` will only return the commands for those.

If noone given all will be returned.

`boot()` always defines `DEBLOGSHELLTAIL`, `DEBMUTE` and `DEBUNMUTE`. These are not returned in the call.

[<sup>TOC</sup>](#toc)

## Using calls

* `g:Deblog2.spew(str msg || [str msg, str msg, ...])` – write to logfile without using command
* `g:Deblog2.objdump(str title, obj object)` – dump object
* `g:Deblog2.evex(str expression)` – Execute `expression` and log result.

* `g:Deblog2.shell([int ntail])` – Open shell with tail. `ntail` is number of lines to include at start.
* `g:Deblog2.wipe()` – Try to remove deblog from environment.
* `g:Deblog2.mute([COMMANS])` – Redirect calls to commands to a Nop function. Optionally *a list* of commands can be given as argument.
* `g:Deblog2.unmute([COMMANDS])` – Returns a *list* of commands that can be executed to re-enable muted commands. NB! The environment from which they are executed wil become the environment where commands can read script variables.
* `g:Deblog2.cmute()` – A soft mute. Calls will go trough, but nothing written to log file.
* `g:Deblog2.cunmute()` – Re-enable writing to log file.

If one want to log local script variables from multiple source files one way is to do:

```vim
call g:Deblog2.objdump("foo2", s:foo2)
```

and the like.

This will *not* include script file or line numbers etc. You *could* add a separate, local command for each script file and call [`cmd_call()`](https://github.com/Termplexed/deblog/blob/09d9780f208b35d78a4830d9a95e16efd57c6c3e/plugin/deblog.vim#L493).

[<sup>TOC</sup>](#toc)

Hack away.
