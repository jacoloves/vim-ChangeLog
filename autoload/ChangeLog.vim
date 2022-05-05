let s:time = strftime("%Y-%m-%d")
let s:sep = fnamemodify('.', ':p')[-1:]
let s:filename = "ChangeLog.txt"
" date search list display buffer name
let s:date_search_list_buffer = 'SEARCH_DATE_LIST'
" keyword search list display buffer name
let s:keyword_search_list_buffer = 'SEARCH_KEYWORD_LIST'

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

    " Store all memo data in an array once. 
    let write_lines = []
    for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)))
        call add(write_lines, line)
    endfor

    " Insert the date in the first row of the array and the tab in the second
    " row.
    call insert(write_lines, title_row, 0)
    call insert(write_lines, tab_space, 1)

    " rewrite file 
    call writefile(write_lines, expand(join([g:changelog_save_path, s:filename], s:sep)))
    
    return 
endfunction

" first time write date
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
    " readfile() outputs a single line of the file contents. 
    if !empty(expand(join([g:changelog_save_path, s:filename], s:sep))) 
        for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)), '', 1)
            " If it does not match the current date, a flag is erected to set
            " a new date.
            if line[0:9] != s:time
                return 1
            endif
        endfor
    endif

    return 0
endfunction

" Get the date 30 days before the current date. 
function! s:date_searchdict() abort
    let lines = []
    let word_line_dict = {}

    let nowtime = localtime()
    let judgeTime = strftime("%Y-%m-%d", nowtime - 1)

    let index = 0
    let line_cnt = 1 
    for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)))
        let minu_day = (60 * 60 * 24 * index)
        if stridx(line, strftime("%Y-%m-%d", nowtime - minu_day)) !=# -1 
            let index = index + 1
            let word_line_dict[line_cnt] = line[0:9]
        endif
        if index == 31
            break
        endif
        let line_cnt = line_cnt + 1
    endfor

    return word_line_dict
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
    " delete SEARCH_DATE_LIST buffer 
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

        " 1. Press 'q' on SEARCH_DATE_LIST to delete buffer
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

" Insert a keyword search in the dictionary
function! s:keyword_searchdict(keyword) abort
    let keyword_line_list = [] 
    let line_cnt = 1
    for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)))
        if stridx(line, expand(a:keyword)) !=# -1
            let composite_str = line_cnt . ":" . line
            call add(keyword_line_list, composite_str)
        endif
        let line_cnt = line_cnt + 1
    endfor
    
    return keyword_line_list
endfunction

" jump search keyword row
function! ChangeLog#jump_keyword_row(target_keyword) abort
    let keywords = split(a:target_keyword, ":")
    let keyword_row = keywords[0]
    
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
    execute keyword_row
    " delete SEARCH_KEYWORD_LIST buffer 
    execute 'bwipeout!' s:keyword_search_list_buffer
    return
endfunction

" display keyword search list process
function! ChangeLog#kewordsearch() abort
    let input_keyword = input(printf("Search Keyword(Words with * at the beginning of the sentence): "), '', )  

    let search_keyword = "* " . input_keyword
    let search_list = s:keyword_searchdict(search_keyword)

    if empty(search_list)
        return
    endif

    if bufexists(s:keyword_search_list_buffer)
        let winid = bufwinid(s:keyword_search_list_buffer)
        if winid isnot# -1
            call win_gotoid(winid)
        else
            execute 'sbuffer' s:keyword_search_list_buffer
        endif
    else
        execute 'new' s:keyword_search_list_buffer
        set buftype=nofile

        " 1. Press 'q' on SEARCH_KEYWORD_LIST to delete buffer
        " 2. Press 'Enter' to jump target date
        " Define two key mappings.
        nnoremap <silent> <buffer>
                    \ <Plug>(keywordsearch-session-close)
                    \ :<C-u>bwipeout!<CR>

        nnoremap <silent> <buffer>
                    \ <Plug>(jump-keyword)
                    \ :<C-u>call ChangeLog#jump_keyword_row(trim(getline('.')))<CR>

       " <Plug> map to key
        nmap <buffer> q <Plug>(keywordsearch-session-close)
        nmap <buffer> <CR> <Plug>(jump-keyword)
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
