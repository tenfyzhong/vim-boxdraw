let s:drawscript = expand('<sfile>:p:h:h') . "/python/boxdraw.py"

function! boxdraw#GetEndPos()
    " Vim reports '< and '> in the wrong order if the end of the selection
    " is in an earlier line than the start of the selection. This is why
    " we need this hack.
    let m = getpos("'m")
    execute "normal! gvmm\<Esc>"
    let p = getpos("'m")
    call setpos("'m", m)
    return p
endfunction

function! boxdraw#GetStartPos(startPos)
    " Returns the 'other corner' of the visual selection.
    let p1 = getpos("'<")
    let p2 = getpos("'>")
    if p1 == a:startPos
        return p2
    else
        return p1
    endif
endfunction

function! boxdraw#Draw(cmd, args)
    let p2 = boxdraw#GetEndPos()
    let p1 = boxdraw#GetStartPos(p2)
    let y1 = p1[1] - 1
    let y2 = p2[1] - 1
    let x1 = p1[2] + p1[3] - 1
    let x2 = p2[2] + p2[3] - 1
    let c = ['python', s:drawscript, shellescape(a:cmd), y1, x1, y2, x2] + a:args
    execute "%!" . join(c, " ")
    call setpos(".", p2)
endfunction

function! boxdraw#DrawWithLabel(cmd, args)
    let label = shellescape(input("Label: "))
    call boxdraw#Draw(a:cmd, [label] + a:args)
endfunction

function! boxdraw#Select(cmd)
    let p2 = boxdraw#GetEndPos()
    let p1 = boxdraw#GetStartPos(p2)
    let y1 = p1[1] - 1
    let y2 = p2[1] - 1
    let x1 = p1[2] + p1[3] - 1
    let x2 = p2[2] + p2[3] - 1

    let contents = join(getline(1,'$'), "\n")
    let c = ['python', s:drawscript, shellescape(a:cmd), y1, x1, y2, x2]
    let result = system(join(c, " "), contents)

    let coords = split(result, ",")

    call setpos("'<", [0, coords[0]+1, coords[1]+1, 0])
    call setpos("'>", [0, coords[2]+1, coords[3]+1, 0])
    normal! gv
endfunction

function! boxdraw#debug()
    echo "debug"
endfunction

" -------- Keyboard mappings --------

let s:mappings = {
            \ '+o': 'call boxdraw#Draw("+o", [])',
            \ '+O': 'call boxdraw#DrawWithLabel("+O", [])',
            \ '+[O': 'call boxdraw#DrawWithLabel("+[O", [])',
            \ '+]O': 'call boxdraw#DrawWithLabel("+]O", [])',
            \ '+{[O': 'call boxdraw#DrawWithLabel("+{[O", [])',
            \ '+{]O': 'call boxdraw#DrawWithLabel("+{]O", [])',
            \ '+}[O': 'call boxdraw#DrawWithLabel("+}[O", [])',
            \ '+}]O': 'call boxdraw#DrawWithLabel("+}]O", [])',
            \ '+c': 'call boxdraw#DrawWithLabel("+c", [])',
            \ '+{c': 'call boxdraw#DrawWithLabel("+{c", [])',
            \ '+}c': 'call boxdraw#DrawWithLabel("+}c", [])',
            \ '+{[c': 'call boxdraw#DrawWithLabel("+{[c", [])',
            \ '+{]c': 'call boxdraw#DrawWithLabel("+{]c", [])',
            \ '+}[c': 'call boxdraw#DrawWithLabel("+}[c", [])',
            \ '+}]c': 'call boxdraw#DrawWithLabel("+}]c", [])',
            \ '+[c': 'call boxdraw#DrawWithLabel("+[c", [])',
            \ '+]c': 'call boxdraw#DrawWithLabel("+]c", [])',
            \ '+D': 'echo boxdraw#debug()',
            \ '+>': 'call boxdraw#Draw("+>", [])',
            \ '+<': 'call boxdraw#Draw("+<", [])',
            \ '+v': 'call boxdraw#Draw("+v", [])',
            \ '+V': 'call boxdraw#Draw("+v", [])',
            \ '+^': 'call boxdraw#Draw("+^", [])',
            \ '++>': 'call boxdraw#Draw("++>", [])',
            \ '++<': 'call boxdraw#Draw("++<", [])',
            \ '++v': 'call boxdraw#Draw("++v", [])',
            \ '++V': 'call boxdraw#Draw("++v", [])',
            \ '++^': 'call boxdraw#Draw("++^", [])',
            \ '+-': 'call boxdraw#Draw("+-", [])',
            \ '+\|': 'call boxdraw#Draw("+\|", [])',
            \ '+_': 'call boxdraw#Draw("+_", [])',
            \ 'ao': 'call boxdraw#Select("ao")',
            \ 'io': 'call boxdraw#Select("io")',
            \}

let s:stores = {}
let s:enabled = 0
let s:virtualedit = &virtualedit

function! s:map(mappings)
    for [lhs, rhs] in items(a:mappings)
        exec printf('vnoremap %s :<C-u>%s<cr>', lhs, rhs)
    endfor
endfunction

function! s:store_map(mappings)
    let l:stores = {}
    for lhs in keys(a:mappings)
        for i in range(len(lhs))
            let to_store_lhs = lhs[:i]
            if has_key(l:stores, to_store_lhs)
                continue
            endif
            let d = maparg(to_store_lhs, 'v', 0, 1)
            if len(d) != 0
                let l:stores[to_store_lhs] = d
                exec printf('vunmap %s', to_store_lhs)
            endif
        endfor
    endfor
    return l:stores
endfunction

function! s:restore_mappings(mappings) abort
    for mapping in values(a:mappings)
        if !has_key(mapping, 'unmapped') && !empty(mapping)
            exe     mapping.mode
                        \ . (mapping.noremap ? 'noremap   ' : 'map ')
                        \ . (mapping.buffer  ? ' <buffer> ' : '')
                        \ . (mapping.expr    ? ' <expr>   ' : '')
                        \ . (mapping.nowait  ? ' <nowait> ' : '')
                        \ . (mapping.silent  ? ' <silent> ' : '')
                        \ .  mapping.lhs
                        \ . ' '
                        \ . substitute(mapping.rhs, '<SID>', '<SNR>'.mapping.sid.'_', 'g')

        elseif has_key(mapping, 'unmapped')
            sil! exe mapping.mode.'unmap '
                        \ .(mapping.buffer ? ' <buffer> ' : '')
                        \ . mapping.lhs
        endif
    endfor
endfunction


function! s:unmap(mappings)
    for lhs in keys(a:mappings)
        exec printf('vunmap %s', lhs)
    endfor
endfunction

function! s:enable()
    if s:enabled == 1
        return
    endif

    let s:enabled = 1
    let &virtualedit = 'all'
    let s:stores = <SID>store_map(s:mappings)
    call <SID>map(s:mappings)
endfunction

function! s:disable()
    if s:enabled == 0
        return
    endif

    let s:enabled = 0
    let &virtualedit = s:virtualedit
    call <SID>unmap(s:mappings)
    call <SID>restore_mappings(s:stores)
endfunction

function! s:toggle()
    if s:enabled
        call s:disable()
    else
        call s:enable()
    endif
endfunction

" command
command! BoxdrawEnable call <SID>enable()
command! BoxdrawDisable call <SID>disable()
command! BoxdrawToggle call <SID>toggle()

" mapping
nnoremap <silent> <Plug>(boxdraw-toggle) :<C-u>BoxdrawToggle<cr>

" status line
function! BoxdrawStatusLine()
    return s:enabled ? 'BM' : ''
endfunction

function! boxdraw#AirlineStatus()
    call airline#parts#define_function('boxdraw', 'BoxdrawStatusLine')
    call airline#parts#define_accent('boxdraw', 'green')
    let g:airline_section_warning .= airline#section#create_right(['boxdraw'])
endfunction

" vim:shiftwidth=4:softtabstop=4
