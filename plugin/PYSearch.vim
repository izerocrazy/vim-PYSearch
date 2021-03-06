if exists("s:did_load_py_search")
  finish
endif
let s:did_load_py_search = 1

let s:CurPath = expand("<sfile>:p:h")
let s:PYDictFile = s:CurPath."/../PYTable.txt"

if !filereadable(s:PYDictFile)
    echomsg "there is no ".s:PYDictFile
    finish
endif

if !exists("s:PYDict")
    let s:PYDict = {}
    for line in readfile(s:PYDictFile)
        let ss = split(line)
        let s:PYDict[ss[0]] = ss[1:]
    endfor
endif

if !exists("g:PYSearchOnlyChinese")
    let g:PYSearchOnlyChinese = 1
endif

func! s:CompareChar(key, target)
    if a:target >= '!' && a:target <= '~'
       if a:key != a:target
           return 0
       else
           return 1
       endif
    endif

    if !has_key(s:PYDict, a:target)
        return 0
    endif

    let tt = s:PYDict[a:target]
    for t in tt
        if a:key == t
            return 1
        endif
    endfor

    return 0
endfunc

func! s:Split2Chars(str)
    let ret = []
    let i = 0

    while i < strlen(a:str)
        if a:str[i] <= '~'
            call add(ret, a:str[i])
            let i = i+1
        else
            call add(ret, strpart(a:str, i, 3))
            let i = i+3
        endif
    endwhile

    return ret
endfunc

func! s:Find(str, keys, ret)
    let kLen = strlen(a:keys)
    let chars = s:Split2Chars(a:str)
    let tLen = len(chars)
    let tIdx = 0
    
    while tIdx+kLen <= tLen
        let bFind = 1
        for kIdx in range(kLen)
            if s:CompareChar(a:keys[kIdx], chars[tIdx+kIdx]) == 0
                let bFind = 0
                break
            endif
        endfor

        if bFind == 1 
            let t = join(chars[tIdx : tIdx+kLen-1], '')
            call s:AddToSet(a:ret, t)
            let tIdx = tIdx + kLen
        else
            let tIdx = tIdx + 1
        endif
    endwhile

   return 1
endfunc

func! s:CheckIsValid(item)
    " 去掉中英文混合的结果
    let chars = s:Split2Chars(a:item)
    let bEnginsh = (chars[0][0]<='~')
    for char in chars[1:]
        let bEnginsh2 = (chars[0][0]<='~')
        if bEnginsh != bEnginsh2
            return 0
        endif

    if g:PYSearchOnlyChinese == 1 && bEnginsh == 1
        return 0
    endif

    return 1
endfunc

func! s:AddToSet(set, item)
    if s:CheckIsValid(a:item) == 0
        return
    endif

    let i = index(a:set, a:item)
    if i == -1
        call add(a:set, a:item)
    endif
endfunc

let s:result = []
func! s:PinYinSearch(keys)
    let s:result = []

    for line in getline(1, "$")
        call s:Find(line, a:keys, s:result)
    endfor

    let @/ = join(s:result, "\\|")
    call feedkeys(":set hls\<CR>n")
endfunc

let s:sIdx = 0
func! s:PinYinNext()
    if empty(s:result)
        return
    endif

    let @/ = s:result[s:sIdx]
    call feedkeys(":set hls\<CR>n")

    let s:sIdx = s:sIdx+1
    if s:sIdx >= len(s:result)
        let s:sIdx = 0
    endif
endfunc

func! s:PinYinTest()
    let ret = []
    let testStr = "这里用来执行中文拼音搜索测试,这种搜索方案也可用于easymotion中"
    " 这里的testStr因为是直接定义在文件里需要转换编码为utf8编码,
    " PYSearch使用getline直接从buffer获取到的内容已经是vim内置的utf8编码
    " 注意只能打开这个文件时,执行PYTest的结果才正确,
    " 因为默认的文件编码都是utf8,而这个文件的编码是gbk
    " 如果当前buffer不是这个文件,那么&fileencoding的值可能是其它值,会导致转码错误
    let utfStr = iconv(testStr, &fileencoding, "utf-8")
    call s:Find(utfStr, "ss", ret)
    echo ret
endfunc

command! -nargs=0 PYSearch call s:PinYinSearch(input('Input the leader chars: '))
command! -nargs=0 PYNext call s:PinYinNext()
command! -nargs=0 PYTest call s:PinYinTest()
" vim: set expandtab
