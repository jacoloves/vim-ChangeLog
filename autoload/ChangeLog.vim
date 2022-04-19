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

" test function
" TODO: Deleted after completion
function! ChangeLog#test() abort
    let lines = []
    "let search_lines = []
    let nowtime = localtime()

    for line in readfile(expand(join([g:changelog_save_path, s:filename], s:sep)))
        call add(lines, line)
    endfor

    let index =0 
    "while index < 31
    "    let minu_day = (60 * 60 * 24 * index)
    "    echo strftime("%Y-%m-%d", nowtime - minu_day)
    "    let index = index + 1
    "endwhile

    for line in lines
        while index < 31
            let minu_day = (60 * 60 * 24 * index)
            let linePart = strpart(line, 0, 10)
            if match(linePart, strftime("%Y-%m-%d", nowtime - minu_day)) !=# -1 
                echo line
                break
            endif
            let index = index + 1
        endwhile
    endfor
endfunction

function! ChangeLog#test_time() abort
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
            let word_linecnt_dict[line] = line_cnt
        endif
        if index == 31
            break
        endif
        let line_cnt = line_cnt + 1
    endfor

    " echo word_linecnt_dict
    let word_keylist = keys(word_linecnt_dict)
    for key in word_keylist
        echo key
        echo word_linecnt_dict[key]
    endfor
    
    
endfunction

" date search list display buffer name
let s:date_search_list_buffer = 'SEARCHDATE_LIST'

" display date search list process
function! ChangeLog#searchDateList() abort
    let search_list = s:date_search_list_buffer()
    if empty(search_list)
        return
    endif
endfunction

function! ChangeLog#main() abort
    call s:create_changelog()
    let changeTitleFlg = s:check_date()
    if changeTitleFlg
        call s:rewrite_date()
    endif

    execute "tabedit " . join([g:changelog_save_path, s:filename], s:sep)

    return

endfunction
