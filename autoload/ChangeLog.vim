let s:time = strftime("%Y-%m-%d")
let s:sep = fnamemodify('.', ':p')[-1:]
let s:filename = "ChangeLog.txt"

" create ChageLog
function! s:create_changelog() abort
   if !filewritable(expand(glob(join([g:changelog_save_path, s:filename], s:sep))))
       execute "redir > " . join([g:changelog_save_path, s:filename], s:sep)
       execute "redir END"
       call s:first_write_date()
   endif
   return
endfunction

" rewrite date
function! s:rewrite_date() abort
    if !exists("g:user_full_name") || empty("g:user_full_name")
        let user_name = "anonymous"
    else
        let user_name = g:user_full_name
    endif

    if !exists("g:user_mail_address") || empty("g:user_mail_address")
        let user_mail_address = "anonymous@hogehoge"
    else
        let user_mail_address = g:user_mail_address
    endif

    let title_row = s:time . " " . user_name . " " . "<" . user_mail_address . ">"

    if !exists("g:tab_space_num") || empty("g:tab_space_num")
        let tab_space = "\t"
    else
        for a in g:tab_space_num
            let tab_space .= " "
        endfor
    endif

    " 一度配列に全てメモデータを格納する
    let write_lines = []
    for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)))
        call add(write_lines, line)
    endfor

    " 配列の1行目に日付、2行目にタブを挿入する
    call insert(write_lines, title_row, 0)
    call insert(write_lines, tab_space, 1)

    " 再度ファイルに書き込む
    call writefile(write_lines, expand(join([g:changelog_save_path, s:filename], s:sep)))
    
    return 
endfunction

function! s:first_write_date() abort
    if !exists("g:user_full_name") || empty("g:user_full_name")
        let user_name = "anonymous"
    else
        let user_name = g:user_full_name
    endif

    if !exists("g:user_mail_address") || empty("g:user_mail_address")
        let user_mail_address = "anonymous@hogehoge"
    else
        let user_mail_address = g:user_mail_address
    endif

    let title_row = s:time . " " . user_name . " " . "<" . user_mail_address . ">"

    if !exists("g:tab_space_num") || empty("g:tab_space_num")
        let tab_space = "\t"
    else
        for a in g:tab_space_num
            let tab_space .= " "
        endfor
    endif

    let lines = [title_row, tab_space] 

    call writefile(lines, expand(join([g:changelog_save_path, s:filename], s:sep)))

    return
endfunction

" read date
function! s:check_date() abort
    " readfile()でファイルの中身を1行だけ出力する。
    if !empty(expand(join([g:changelog_save_path, s:filename], s:sep))) 
        for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)), '', 1)
            " 現在の日付と一致しない場合は新しい日付セッティングするフラグを立てる
            if line[0:9] != s:time
                return 1
            endif
        endfor
    endif

    return 0
endfunction

function! s:date_searchdict() abort
    let lines = []
    let word_linecnt_dict = {}

    for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)))
        call add(lines, line)
    endfor

    let nowtime = localtime()
    let judgeTime = strftime("%Y-%m-%d", nowtime - 1)

    let index = 0
    let line_cnt = 1 
    for line in lines
        let minu_day = (60 * 60 * 24 * index)
        if stridx(line, strftime("%Y-%m-%d", nowtime - minu_day)) !=# -1 
            let index = index + 1
            let word_linecnt_dict[line_cnt] = line[0:9]
        endif
        if index == 31
            break
        endif
        let line_cnt = line_cnt + 1
    endfor

    return word_linecnt_dict
endfunction

" date search list display buffer name
let s:date_search_list_buffer = 'SEARCHDATE_LIST'

function! ChangeLog#test() abort
    let changelog_path = join([g:changelog_save_path, s:filename], s:sep)
    if bufexists(changelog_path) 
        let winid = bufwinid(changelog_path)
        if winid isnot# -1
            call win_gotoid(winid)
        else
            execute 'sbuffer ' changelog_path
        endif
    else
        execute 'new' changelog_path
    endif
    execute '3'
    execute 'bwpiout! ' s:date_search_list_buffer
    return
endfunction

" jump search date row
function! ChangeLog#jump_date_row(target_date) abort
    let date_row = ''
    for [key, value] in items(s:date_searchdict())
        if value == a:target_date
            let date_row = key
            break
        endif
    endfor

    let changelog_path = join([g:changelog_save_path, s:filename], s:sep)
    if bufexists(changelog_path) 
        let winid = bufwinid(changelog_path)
        if winid isnot# -1
            call win_gotoid(winid)
        else
            execute 'buffer ' changelog_path
        endif
    else
        execute 'new' changelog_path
    endif
    execute date_row
    execute 'bwipeout!' s:date_search_list_buffer
    return
endfunction

" display date search list process
function! ChangeLog#searchDateList() abort
    let search_dict = s:date_searchdict()
    let search_list = []

    for k in keys(search_dict)
       call add(search_list, search_dict[k]) 
    endfor

    if empty(search_list)
        return
    endif
    
    if bufexists(s:date_search_list_buffer)
        let winid = bufwinid(s:date_search_list_buffer)
        if winid isnot# -1
            call win_gotoid(winid)
        else
            execute 'sbuffer' s:date_search_list_buffer
        endif
    else
        execute 'new' s:date_search_list_buffer
        set buftype=nofile

        " 1. Press 'q' on SEARCHDATE_LIST to delete buffer
        " 2. Press 'Enter' to jump target date
        " Define two key mappings.
        nnoremap <silent> <buffer>
                    \ <Plug>(datesearch-session-close)
                    \ :<C-u>bwipeout!<CR>

        nnoremap <silent> <buffer>
                    \ <Plug>(jump-date)
                    \ :<C-u>call ChangeLog#jump_date_row(trim(getline('.')))<CR>

       " <Plug> map to key
       nmap <buffer> q <Plug>(datesearch-session-close)
       nmap <buffer> <CR> <Plug>(jump-date)
    endif

    " Delete all text in the temporary buffer and insert the retrieved date
    " search list into the buffer.
    %delete _
    call setline(1, search_list)
endfunction

function! ChangeLog#main() abort
    call s:create_changelog()
    let changeTitleFlg = s:check_date()
    if changeTitleFlg
        call s:rewrite_date()
    endif

    execute "buffer " . join([g:changelog_save_path, s:filename], s:sep)

    return

endfunction
