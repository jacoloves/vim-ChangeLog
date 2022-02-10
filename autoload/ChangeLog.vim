let s:time = strftime("%Y-%m-%d")
let s:sep = fnamemodify('.', ':p')[-1:]
let s:filename = "ChangeLog.txt"
let s:tmpFilename = "ChangeLog_tmp.txt"

" create ChageLog
function! s:create_changelog() abort
   if !filewritable(expand(glob(join([g:changelog_save_path, s:filename], s:sep))))
       execute "redir > " . join([g:changelog_save_path, s:filename], s:sep)
       execute "redir END"
   endif

   return
endfunction

" write date
function! s:write_date() abort
    if !exists("g:user-full-name") || empty("g:user-full-name")
        let user_name = "anonymous"
    else
        let user_name = g:user-full-name
    endif

    if !exists("g:user-mail-address") || empty("g:user-mail-address")
        let user_mail_address = "anonymous@hogehoge"
    else
        let user_mail_address = g:user-mail-address
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

    call writefile(readfile(join([g:changelog_save_path, s:filename], s:sep)), join([g:changelog_save_path, s:tmpFilename], s:sep))

    call writefile(lines, join([g:changelog_save_path, s:filename], s:sep))
    
    call writefile(readfile(join([g:changelog_save_path, s:tmpFilename], s:sep)), join([g:changelog_save_path, s:filename], s:sep), "a")

    call delete(expand(join([g:changelog_save_path, s:tmpFilename], s:sep)))

    return 
endfunction

" read date
function! s:check_date() abort
    " readfile()でファイルの中身を1行だけ出力する。
    for line in readfile(join([g:changelog_save_path, s:filename], s:sep), '', 1)
        " 現在の日付と一致しない場合は新しい日付セッティングするフラグを立てる
        if line[0:9] != s:time
            return 1
        endif
    endfor
    
    return 0
endfunction

" test function
" TODO: Deleted after completion
function! ChangeLog#test() abort
    let changeTitleFlg = s:check_date()
    call ChangeLog#test2(changeTitleFlg)
endfunction

" test function
" TODO: Deleted after completion
function! ChangeLog#test2(changeFlg)
    if a:changeFlg
        echo "Change!!"
    else
        echo "No, Change..."
    endif
endfunction

function! ChangeLog#main() abort
    let changeTitleFlg = s:check_date()
    call s:create_changelog()
    if changeTitleFlg
        call s:write_date()
    endif

    execute "tabedit " . join([g:changelog_save_path, s:filename], s:sep)

    return

endfunction
