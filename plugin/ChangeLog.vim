if exists('g:loaded_changelog')
    finish
endif

let g:loaded_changelog = 1

command! ChangeLogOpen call ChangeLog#main()
command! SearchDateChangeLog call ChangeLog#searchDate()
command! SearchKeywordChangeLog call ChangeLog#searchKeyword()
