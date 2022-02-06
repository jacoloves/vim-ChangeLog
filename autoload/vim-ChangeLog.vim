let s:time = strftime("%Y-%m-%d")
let s:sep = fnamemodify('.', ':p')[-1:]
let s:filename = "ChangeLog.txt"

" create ChageLog
function! s:create_changelog() abort
   if !filewritable(expand(glob(join([g:changelog_save_path, s:filename], s:sep))))
       execute "redir > " . join([g:changelog_save_path, s:filename], s:sep)
       execute "redir END"
   endif
endfunction

" write date
function! s:write_date() abort
    let s:user_name = ""
    if !exists("g:user-full-name") || empty("g:user-full-name")
        s:user_name = "anonymous"
    else
        s:user_name = g:user-full-name
    endif

    let s:user_mail_address = ""
    if !exists("g:user-mail-address") || empty("g:user-mail-address")
        s:user_mail_address = "anonymous@hogehoge"
    else
        s:user_mail_address = g:user-mail-address
    endif

    let s:title_row = s:time + " " + s:user_name + " " + "<" + s:user_mail_address + ">"
endfunction



function! changelog#main() abort
    call s:create_changelog()

endfunction
