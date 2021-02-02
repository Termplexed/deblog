" vim: fdm=marker
" """""""""""""""""""""""""""""""""""""""""""""""""""""""" Figlet -w 80 -c -f 3d
"                                                                              "
"               ███████           ██       ██                                  "
"              ░██░░░░██         ░██      ░██           █████                  "
"              ░██    ░██  █████ ░██      ░██  ██████  ██░░░██                 "
"              ░██    ░██ ██░░░██░██████  ░██ ██░░░░██░██  ░██                 "
"              ░██    ░██░███████░██░░░██ ░██░██   ░██░░██████                 "
"              ░██    ██ ░██░░░░ ░██  ░██ ░██░██   ░██ ░░░░░██                 "
"              ░███████  ░░██████░██████  ███░░██████   █████                  "
"                                                                              "
"                                                                              "
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Termplexed
" https://github.com/Termplexed/deblog
"
" D s:Deblog2 {  }                                The  Deblog2  DICT {{{1
"
let s:cpo_bak = &cpo
set cpo&vim

if exists('s:Deblog2.cnf')
	" Re-applied in s:Deblog2.bootstrap()
	let s:cnf_bak = copy(s:Deblog2.cnf)
	unlet g:Deblog2
	unlet s:Deblog2
endif
if exists('s:Deblog2_purge_all')
	call s:Deblog2_purge_all()
	unlet s:Deblog2_purge_all
endif

" System
if !exists('s:sys')
	let s:sys = {
		\'is_win'       : has("win16") || has("win32") ||
				\ has("win64") || has("win95"),
		\'has_reltime'  : has('reltime')
		\}
endif

" VTs to open with the :DEBLOGSHELLTAIL command
let s:shells = {
	\ 'uxterm' : 'uxterm ' .
		\ '-fa "Liberation Mono" -fs 8 -fg ivory ' .
		\ '-bg black -geometry 85x90-0+0 +sb -sl 500 ' .
		\ '-T "VDL #FILE#" ' .
		\ '-e "tail #NTAIL# -f #FILE#"',
	\ 'xfce' : 'xfce4-terminal ' .
		\ '--font "Liberation Mono 8" ' .
		\ '--geometry 85x90-0+0 ' .
		\ '-T "VDL #FILE#" ' .
		\ '-e "tail #NTAIL# -f #FILE#"',
	\ 'kitty' : 'kitty ' .
		\ '-T="VDL #FILE#" ' .
		\ ' tail #NTAIL# -f #FILE#'
	\ }

" Some possible tunings:
"
" deblog:    What to log. 'f' = to file
" file:      XXX Write to file XXX
" htime:     If N seconds has passed since last log print, add header
" cmd_shell: shell config to use for :DEBLOGSHELLTAIL (See above s:shells)
"
let s:Deblog2 = {
	\ 'version'     : '0.1.1',
	\ 'public_name' : 'g:Deblog2',
	\ 'cnf'         : { },
	\ 'strapped'    : 0,
	\ 'deblog'      : 'fiwh',
	\ 'file'        : $HOME.(s:sys.is_win ? '/' : '/.vim/').
						\ 'my_deblog.log',
	\ 'htime'       : s:sys.has_reltime ? 0.5 : 1,
	\ 'timestamp'   : 1,
	\ 'tt_prev'     : s:sys.has_reltime ? 0.0 : 0,
	\ 'separator'   : ';;' . repeat(' -', 45),
	\ 'cmd_shell'   : s:shells.uxterm,
	\ 'ntail'       : 20,
	\ 'buf'         : []
	\}

" }}}
" D s:cnf_default                                Default config DICT {{{1
"
" fn_expand:  expr  expansion to use when printing source file name
" linen:      bool  print linenumber of call
" ep_fun:     bool  print function of call
let s:cnf_default = {
	\ 'fn_expand': ':t',
	\ 'linen': 1,
	\ 'ep_fun': 1,
	\ 'colors': {
		\ 'fn': 'green',
		\ 'ln': '1;red',
		\ 'fun': '1;blue'
		\}
	\}
" }}}


" XXX: Does not unload commands ...
" See s:Deblog.wipe()
function! s:Deblog2_purge_all()
    if exists('s:Deblog2')
	unlet s:Deblog2
	unlet s:sys
	unlet s:shells
	"unlet s:cnf_default
	unlet s:colors
	unlet s:C
	"unlet s:Commands
	unlet g:Deblog2
    endif
endfunction

" Generate time string for log
"
" If now - last time >= self.htime push a separator to out buffer.
" If self.timestamp = true use time stamp
"
function! s:Deblog2.push_log_separator() dict
	let r = 0
	let cur_t = s:sys.has_reltime ? str2float(reltimestr(reltime()))
				\ : localtime()
	let self.delta = cur_t - self.tt_prev
	if self.htime >= 0 && self.delta >= self.htime
		let self.tt_acum = 0.0
		if self.timestamp
			let sep = ';;' . strftime('%Y-%m-%d %H:%M:%S')
			if s:sys.has_reltime
				let sep .= '.' . split(printf("%f", cur_t), '\.')[1]
			endif
			"let sep = (sep . ' ' . self.separator)[0:45]
		else
			let sep = self.separator
		endif
		let self.buf += [ "\033[1;45;37m\033[2K" . sep . "\033[0m"]
		let r = 1
	else
		let self.tt_acum += self.delta
	endif
	let self.tt_prev = cur_t
	return r
endfunction

function! s:Deblog2.spew(msg, ...) dict
	if self.deblog =~ 'f' || (a:0 == 1 && a:1 == 1)
		"let s:mysid= expand('<sfile>')
		if self.file != '' && filewritable(self.file) == 1
			let s = self.push_log_separator()
			let tmp = a:msg
			if type(tmp) != type([])
				let tmp = split(tmp, "\n")
			endif
			let tt = s ? 0.0 : self.delta
			let tmp[0] = "[" . printf("%f | %f", tt, self.tt_acum) . "] " . tmp[0]
			call extend(self.buf, tmp)
			"call writefile(['self.buf'], self.file, "a")
			call writefile(self.buf, self.file, "a")
			unlet self.buf
			let self.buf = []
		endif
	endif
endfunction
let s:colors = {
	\ 'num'   : 'red',
	\ 'str'   : 'yellow',
	\ 'fun'   : 'blue',
	\ 'list'  : 'green',
	\ 'dict'  : 'green',
	\ 'float' : 'magenta',
	\ 'bool'  : '1;cyan',
	\ 'null'  : '1;red',
	\ 'job'   : 'white',
	\ 'chan'  : 'white',
	\ 'blob'  : 'white'
\}

" Return
" [ func_ref_nr, argv, file, line ]
function! s:Deblog2.fun_foo(f)
	let r = []
	let src = split(trim(execute('verbose function a:f')), '\n')
	let fref = matchlist(src[0],
			\ '\s*function ' .
			\ '\([^(]\+\)' .
			\ '(\([^)]*\))')
	let file = matchlist(src[1], '\s*Last set from \(.*\)\%($\| line \(\d\+\)$\)')
	try
		if len(fref)
			let r += [ fref[1], fref[2] ]
		endif
		if len(file)
			let r += [ file[1], file[2] ]
		endif
	catch
		call self.spew("SRC>>".string(src)."<<")
		call self.spew("FR>>".string(fref)."<<")
		call self.spew("FI>>".string(file)."<<")
	endtry
	if ! len(r)
		let r = ['?', '', '']
	endif
	return r
endfun

function! s:Deblog2.objdump(name, obj, ...) dict
	let indent = a:0 > 0 ? a:1 : 0
	let wn = -20 - 9
	let wv = -29 + indent
	let cd = 'white'
	let fob = []
	if type(a:obj) == type(function("tr"))
		let fob = self.fun_foo(a:obj)
	endif
	let name = s:C.bword(a:name, 'white')
	if type(a:obj) == type(0)                   " Number     t=0
		let color = get(s:colors, 'num', cd)
		"let name = indent ? string(a:name) : a:name
		let wv -= 9
		call self.spew(printf(
			\ '%*s%*s :  %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, s:C.word(a:obj+0, color),
			\ "Number"
			\ ))
	elseif type(a:obj) == type("")              " String     t=1
		"let name = indent ? string(a:name) : a:name
		let color = get(s:colors, 'str', cd)
		let wv -= 10
		call self.spew(printf(
			\ '%*s%*s : %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, string(s:C.word(a:obj, color)),
			\ "String"
			\ ))
	elseif type(a:obj) == type(function("tr"))  " Funcref    t=2
		let color = get(s:colors, 'fun', cd)
		let wv -= 9
		call self.spew(printf(
			\ '%*s%*s :  %*s " %s (%s)',
			\ indent, "",
			\ wn, '.' . name,
			\ wv, '(' . s:C.word(fob[1], color) . ')',
			\ "Funcref", fob[0]
			\ ))
	elseif type(a:obj) == type([])              " List       t=3
		"let name = indent ? string(a:name) : a:name
		let color = get(s:colors, 'list', cd)
		let bo = s:C.word("[", color)
		let bc = s:C.word("]", color)
		call self.spew(printf(
			\ '%*s%*s %s  %*s " %s',
			\ indent, "",
			\ wn, name ,
			\ bo,
			\ wv, "",
			\ "List"
			\ ))
		let i = 0
		for el in a:obj
			call self.objdump(i, el, indent + 2)
			let i += 1
		endfor
		call self.spew(printf('%*s' . bc, indent, ""))
		"call self.spew_list(a:name, a:obj, indent)
	elseif type(a:obj) == type({})              " Dictionary t=4
		"let name = indent ? string(a:name) : a:name
		let color = get(s:colors, 'dict', cd)
		let bo = s:C.word("{", color)
		let bc = s:C.word("}", color)
		call self.spew(printf(
			\ '%*s%*s  %*s " %s',
			\ indent, "",
			\ wn, a:name . " " . bo,
			\ 2, "",
			\ "Dictionary"
			\ ))
		for k in keys(a:obj)
			call self.objdump(k, a:obj[k], indent + 2)
		endfor
		call self.spew(printf('%*s' . bc, indent, ""))
	elseif type(a:obj) == type(0.0)             " Float      t=5
		"let wv += 11
		let wv -= 9
		let color = get(s:colors, 'float', cd)
		let vv = s:C.word(printf("%.4f", a:obj), color)
		call self.spew(printf(
			\ '%*s%*s :  %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, vv,
			\ "Float"
			\ ))
	elseif type(a:obj) == type(v:false)         " Boolean   t=6
		let wv -= 11
		let color = get(s:colors, 'bool', cd)
		let vv = s:C.word((a:obj ? 'TRUE' : 'FALSE'), color)
		call self.spew(printf(
			\ '%*s%*s :  %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, vv,
			\ "Boolean"
			\ ))
	elseif type(a:obj) == type(v:null)          " NULL     t=7
		let wv -= 11
		let color = get(s:colors, 'null', cd)
		call self.spew(printf(
			\ '%*s%*s :  %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, s:C.word((a:obj == v:null ? 'NULL' : 'NONE'), color),
			\ "None"
			\ ))
	elseif type(a:obj) == v:t_job               " Job       t=8
		let jinf = job_info(a:obj)
		call self.spew(printf(
			\ '%*s%*s {  %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, "",
			\ "Job"
			\ ))
		for k in keys(jinf)
			call self.objdump(k, jinf[k], indent + 2)
		endfor
		call self.spew(printf('%*s}', indent, ""))
	elseif type(a:obj) == v:t_channel            " Channel  t=9
		let ch = ch_info(a:obj)
		call self.spew(printf(
			\ '%*s%*s {  %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, "",
			\ "Channel"
			\ ))
		for k in keys(ch)
			call self.objdump(k, ch[k], indent + 2)
		endfor
		call self.spew(printf('%*s}', indent, ""))
	elseif type(a:obj) == v:t_blob              " Blob     t=10
		let blob = printf("%s[%d]", a:obj[0:3], len(a:obj))
		call self.spew(printf(
			\ '%*s%*s :  %*s " %s',
			\ indent, "",
			\ wn, name,
			\ wv, blob,
			\ "Blob"
			\ ))
	else
		call self.spew(printf(
			\ '%*s%*s :  %*s " %s => type %d',
			\ indent, "",
			\ wn, name,
			\ wv, string(a:obj),
			\ "ERR.Unknown",
			\ type(a:obj)
			\ ))
	endif
endfun

" This is ugly - use at own risk
function! s:Deblog2.evex(expr, ...) dict
	let eme = v:errmsg
	let v:errmsg = ""
	if a:expr[0] == ":"
		let res = execute(a:expr, "silent!")
	else
		let res = eval(a:expr)
	endif
	if v:errmsg != ""
		call self.spew('Unable to execute `' . a:expr . "'")
		call self.spew(string(res))
		call self.warning('Unable to execute, gave ' . v:errmsg)
		if a:expr[0] != ":"
			call self.info('Remember ":" in front of ex calls')
		endif
	else
		call self.objdump('Exec: ' . string(a:expr), res)
	endif
	let v:errmsg = eme
	return 0
endfunction

function! s:Deblog2.shell(...) dict
	if self.cmd_shell != ''
		let cmd = substitute(self.cmd_shell, '#FILE#', self.file, 'g')
		if match(cmd, '#NTAIL#')
			let nnn = a:0 && type(a:1) == type(0) ? a:1 : self.ntail
			let cmd = substitute(cmd, '#NTAIL#', '-n' . nnn, 'g')
		endif
		call system(cmd . ' &')
	endif
endfunction

function! s:Deblog2.filecheck() dict
	if self.deblog !~ 'f'
		return -1
	endif

	if self.file == ''
		call self.warning(
		\ 'Deblog2 :: outfile is "" - nothing will be written.')
		let self.deblog = substitute(self.deblog, 'f', '', '')
		return 0
	endif

	" Iff file presumably does not exist - fake a touch
	if !filereadable(self.file)
		echon "\r"
		exe 'redir >> ' . self.file
		silent echon ''
		redir END
	endif

	if !filewritable(self.file)
		call self.warning("Deblog2 :: can't write to " . self.file .
					\ " - nothing will be written.")
		let self.deblog = substitute(self.deblog, 'f', '', '')
		return 0
	endif

	return 1
endfunction

fun! s:Deblog2.bootstrap()
	call extend(s:Deblog2.cnf, s:cnf_default)
	if exists('s:cnf_bak')
		call extend(s:Deblog2.cnf, s:cnf_bak)
		unlet s:cnf_bak
	endif
	if ! self.strapped
		let self.strapped = 1
		call self.filecheck()
	endif
	"call self.def_commands()
	"call self.autocmd_set(0)
endfun

" XXX
" This is a mess ... ! :facepalm:
" XXX
let s:C = { 'c': {
	\ 'black' : '30', 'red'     : '31', 'green' : '32', 'yellow'  : '33',
	\ 'blue'  : '34', 'magenta' : '35', 'cyan'  : '36', 'white'   : '37',
	\ '1;black'  : '1;30', '1;red'   : '1;31', '1;green'   : '1;32',
	\ '1;yellow' : '1;33', '1;blue'  : '1;34', '1;magenta' : '1;35',
	\ '1;cyan'   : '1;36', '1;white' : '1;37',
	\ 'Black' : '40', 'Red'     : '41', 'Green' : '42', 'Yellow' : '43',
	\ 'Blue'  : '44', 'Magenta' : '45', 'Cyan'  : '46', 'White'  : '47'
	\},
	\ 'z' : "\033[0m"
\}
function! s:C.fg(c)
	return "\033[" . self.c[a:c] . "m"
endfunction
function! s:C.bfg(c)
	return "\033[1;" . self.c[a:c] . "m"
endfunction
function! s:C.word(s, c)
	return "\033[" . self.c[a:c] . "m" . a:s . "\033[0m"
endfunction
function! s:C.bword(s, c)
	return "\033[1;" . self.c[a:c] . "m" . a:s . "\033[0m"
endfunction
function! s:C.bg(c)
	return "\033[" . self.c[a:c]
endfunction

function! s:Deblog2.res_fun(s)
	let as = split(a:s, '\.\.')
	"call s:Deblog.dump('a:s', a:s)
	"call s:Deblog.dump('as', as)
	let fnr = as[-1]
	let fnra = matchstr(fnr, '^\(function \)\?\zs.\+$')
	let fnr = fnra == '' ? fnr : fnra
	if fnr != ''
		let fex = fnr =~ '^\d' ? '{'.fnr.'}' : fnr
		let fa = split(execute('verbose function ' . fex), '\n')
		let f = matchstr(fa[1],
			\ '^\s*Last set from \zs.\{-}\ze line \d\+$')
	else
		let f = a:s
	endif
	let f = fnamemodify(f, self.cnf.fn_expand)
	return [f, fnr]
endfunction

function! s:Deblog2.cmd_call(fn, line, cmd, ...)
	"call self.spew(a:fn)
	if a:fn =~ '^/'
		let fnd = split(a:fn, '\.vim\[[0-9]\+\]\.\.')
		if len(fnd) > 1
			try
				let fnd = self.res_fun(a:fn)
			catch
				let fnd = [a:fn, '']
			endtry
		else
			let fnd = [ fnamemodify(a:fn, self.cnf.fn_expand), '' ]
		endif
	else
		try
			let fnd = self.res_fun(a:fn)
		catch
			let fnd = [a:fn, '']
		endtry
	endif
	let pfx = []
	if [self.cnf.fn_expand] != [0]
		let pfx += [s:C.word(
			\ fnd[0],
			\ self.cnf.colors.fn)]
	endif
	if [self.cnf.linen] != [0]
		let pfx += [s:C.word(
			\ a:line,
			\ self.cnf.colors.ln)]
	endif
	if [self.cnf.ep_fun] != [0]
		let pfx += [s:C.word(
			\ fnd[1],
			\ self.cnf.colors.fun)]
	endif
	let pfx = join(pfx, ':')
	if a:cmd == 'objdump'
		for a in a:000
			call self.objdump(pfx, a)
		endfor
	elseif a:cmd == 'spew'
		for a in a:000
			call self.spew(pfx . ": " .  a)
		endfor
	endif
endfun

" Due to restriction in namespaces commands need to be set from the vim file
" where script objects reside that one want to log / dump.
"
" DUMP:            Object dump
" LLOG:            Log with file:linenumber:function: <data>
" LLOG2+:          If one want to split it up. Each can be silenced.
" LOG:             Plain log
" QLOG:            Plain log quoted
" EXLOG:           Log result of command. NB! Lives in this file (namespace)
"                  Intended for
"
" Global and set on boot:
" DEBLOGSHELLTAIL: Open shell with logfile
" DEBMUTE:         Calls are made, but nothing written to file
" DEBUNMUTE:       Write to file
let s:Commands =
	\ {
	\ "DUMP" : "command! -nargs=+ -complete=function DUMP :call g:Deblog2.cmd_call(
	\ expand(\"<sfile>\"),
	\ expand(\"<sflnum>\"),
	\ 'objdump',
	\ <args>
	\ )",
	\ "LLOG" : "command! -nargs=+ LLOG :call g:Deblog2.cmd_call(
	\ expand(\"<sfile>\"),
	\ expand(\"<sflnum>\"),
	\ 'spew',
	\ <args>
	\ )",
	\ "LLOG2" : "command! -nargs=+ LLOG2 :call g:Deblog2.cmd_call(
	\ expand(\"<sfile>\"),
	\ expand(\"<sflnum>\"),
	\ 'spew',
	\ <args>
	\ )",
	\ "LLOG3" : "command! -nargs=+ LLOG3 :call g:Deblog2.cmd_call(
	\ expand(\"<sfile>\"),
	\ expand(\"<sflnum>\"),
	\ 'spew',
	\ <args>
	\ )",
	\ "LLOG4" : "command! -nargs=+ LLOG4 :call g:Deblog2.cmd_ccall(
	\ expand(\"<sfile>\"),
	\ expand(\"<sflnum>\"),
	\ 'spew',
	\ <args>
	\ )",
	\ "LOG"  : "command! -nargs=+ LOG  :call g:Deblog2.spew(<args>)",
	\ "QLOG" : "command! -nargs=+ QLOG :call g:Deblog2.spew(<q-args>)",
	\ "EXLOG" : "command! -nargs=+ EXLOG :call g:Deblog2.evex(<q-args>)",
	\ }
" void function for silencing
fun! Nop()
endfun
fun! s:filter_cmd_keys(v, k)
	let cc = a:k ? a:k : keys(s:Commands)
	if len(a:v) > 0
		call filter(cc, 'index(a:v, v:val) > -1')
	endif
	return cc
endfun
function! s:Deblog2.wipe(...)
	for k in keys(s:Commands) + ['DEBLOGSHELLTAIL', 'DEBMUTE', 'DEBUNMUTE']
		if exists(":" . k)
			exe "delcommand " . k
		endif
	endfor
	call s:Deblog2_purge_all()
endfun
function! s:Deblog2.mute(...)
	let cc = a:0 > 0 ? a:1 : keys(s:Commands)
	for k in cc
		if exists(":" . k)
			exe "command! -nargs=* " . k . " :call Nop()"
		endif
	endfor
endfun
function! s:Deblog2.unmute(...)
	let rv = []
	if a:0 > 0
		for k in a:1
			call add(rv, s:Commands[k])
		endfor
	else
		let rv = values(s:Commands)
	endif
	return rv
endfun
function! s:Deblog2.cmute()
	let g:Deblog2.deblog = ''
endfun
function! s:Deblog2.cunmute()
	let g:Deblog2.deblog = 'fiwh'
endfun
function! s:Deblog2.boot(...)
	command! -nargs=* DEBLOGSHELLTAIL :silent call g:Deblog2.shell(<args>)
	command! -nargs=0 DEBMUTE :call g:Deblog2.cmute()
	command! -nargs=0 DEBUNMUTE :call g:Deblog2.cunmute()

	if a:0 > 0
		return s:Deblog2.unmute(a:1)
	else
		return s:Deblog2.unmute()
	endif
endfun

call s:Deblog2.bootstrap()

let g:Deblog2 = deepcopy(s:Deblog2)

let &cpo= s:cpo_bak
unlet s:cpo_bak
