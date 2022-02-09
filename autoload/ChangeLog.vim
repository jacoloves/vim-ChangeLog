let s:time = strftime("%Y-%m-%d")
let s:sep = fnamemodify('.', ':p')[-1:]
let s:filename = "ChangeLog.txt"

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
        let tab_space = "    "
    else
        for a in g:tab_space_num
            let tab_space .= " "
        endfor
    endif

    let lines = [title_row, tab_space] 

    call writefile(lines, join([g:changelog_save_path, s:filename], s:sep))
    
    return 
endfunction



function! ChangeLog#main() abort
    call s:create_changelog()
    call s:write_date()

    return

endfunction
