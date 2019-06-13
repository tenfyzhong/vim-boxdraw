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
            \ '+o': ':<c-u>call boxdraw#Draw("+o", [])<cr>',
            \ '+O': ':<c-u>call boxdraw#DrawWithLabel("+O", [])<cr>',
            \ '+[O': ':<c-u>call boxdraw#DrawWithLabel("+[O", [])<cr>',
            \ '+]O': ':<c-u>call boxdraw#DrawWithLabel("+]O", [])<cr>',
            \ '+{[O': ':<c-u>call boxdraw#DrawWithLabel("+{[O", [])<cr>',
            \ '+{]O': ':<c-u>call boxdraw#DrawWithLabel("+{]O", [])<cr>',
            \ '+}[O': ':<c-u>call boxdraw#DrawWithLabel("+}[O", [])<cr>',
            \ '+}]O': ':<c-u>call boxdraw#DrawWithLabel("+}]O", [])<cr>',
            \ '+c': ':<c-u>call boxdraw#DrawWithLabel("+c", [])<cr>',
            \ '+{c': ':<c-u>call boxdraw#DrawWithLabel("+{c", [])<cr>',
            \ '+}c': ':<c-u>call boxdraw#DrawWithLabel("+}c", [])<cr>',
            \ '+{[c': ':<c-u>call boxdraw#DrawWithLabel("+{[c", [])<cr>',
            \ '+{]c': ':<c-u>call boxdraw#DrawWithLabel("+{]c", [])<cr>',
            \ '+}[c': ':<c-u>call boxdraw#DrawWithLabel("+}[c", [])<cr>',
            \ '+}]c': ':<c-u>call boxdraw#DrawWithLabel("+}]c", [])<cr>',
            \ '+[c': ':<c-u>call boxdraw#DrawWithLabel("+[c", [])<cr>',
            \ '+]c': ':<c-u>call boxdraw#DrawWithLabel("+]c", [])<cr>',
            \ '+D': ':<c-u>echo boxdraw#debug()<cr>',
            \ '+>': ':<c-u>call boxdraw#Draw("+>", [])<cr>',
            \ '+<': ':<c-u>call boxdraw#Draw("+<", [])<cr>',
            \ '+v': ':<c-u>call boxdraw#Draw("+v", [])<cr>',
            \ '+V': ':<c-u>call boxdraw#Draw("+v", [])<cr>',
            \ '+^': ':<c-u>call boxdraw#Draw("+^", [])<cr>',
            \ '++>': ':<c-u>call boxdraw#Draw("++>", [])<cr>',
            \ '++<': ':<c-u>call boxdraw#Draw("++<", [])<cr>',
            \ '++v': ':<c-u>call boxdraw#Draw("++v", [])<cr>',
            \ '++V': ':<c-u>call boxdraw#Draw("++v", [])<cr>',
            \ '++^': ':<c-u>call boxdraw#Draw("++^", [])<cr>',
            \ '+-': ':<c-u>call boxdraw#Draw("+-", [])<cr>',
            \ '+\|': ':<c-u>call boxdraw#Draw("+\|", [])<cr>',
            \ '+_': ':<c-u>call boxdraw#Draw("+_", [])<cr>',
            \ 'ao': ':<c-u>call boxdraw#Select("ao")<cr>',
            \ 'io': ':<c-u>call boxdraw#Select("io")<cr>',
            \}

let s:stores = {}
let s:enabled = 0
let s:virtualedit = &virtualedit

function! s:map(mappings)
    let result = []
    for [lhs, rhs] in items(a:mappings)
        let mapping = mode#mapping#create('v', 1, 0, lhs, rhs)
        call add(result, mapping)
    endfor
    return result
endfunction

let s:inited = 0
function! s:init()
    if !s:inited
        try
            call mode#add('boxdraw', 'B', <SID>map(s:mappings))
            let s:inited = 1
        catch /^E117/
            echom 'Please install https://github.com/tenfyzhong/mode.vim first'
            return
        endtry
    endif
endfunction

function! s:enable()

    let &virtualedit = 'all'
    call mode#enable('boxdraw')
endfunction

function! s:disable()
    let &virtualedit = s:virtualedit
    call mode#disable('boxdraw')
endfunction

function! s:toggle()
    if s:enabled
        call s:disable()
    else
        call s:enable()
    endif
endfunction

call <SID>init()

" command
command! BoxdrawEnable call <SID>enable()
command! BoxdrawDisable call <SID>disable()
command! BoxdrawToggle call <SID>toggle()


" mapping
nnoremap <silent> <Plug>(boxdraw-toggle) :<C-u>BoxdrawToggle<cr>

