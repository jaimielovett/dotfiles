" Spawn syntax, based on Projects/spawn/compiler/lexer.cpp and docs/language.
if exists('b:current_syntax')
  finish
endif

syntax case match
syntax keyword spawnConditional if else
syntax keyword spawnStatement return
" Reserved constructs documented by the language, including planned syntax.
syntax keyword spawnRepeat while for
syntax keyword spawnStructure struct
syntax keyword spawnBoolean true false
syntax keyword spawnConstant uninit
syntax keyword spawnType auto bool string i8 i16 i32 i64 u8 u16 u32 u64 f32 f64
syntax match spawnNumber '\<\d\+\%(\.\d\+\)\?\>'
syntax match spawnFunction '\<[A-Za-z_][A-Za-z0-9_]*\>\ze\s*('
syntax match spawnFunction '\<[A-Za-z_][A-Za-z0-9_]*\>\ze\s*::\s*('
syntax match spawnOperator '::\|:=\|->\|/=\|<=\|>=\|[+*/=<>@-]'
syntax match spawnDelimiter '[(){}\[\],.:]'
" Later matches win: distinguish the multi-character operators from colons.
syntax match spawnOperator '::\|:=\|->'
syntax match spawnEscapeError '\\.' contained
syntax match spawnEscape '\\[nrt"\\]' contained
syntax region spawnString start='"' skip='\\.' end='"' oneline contains=spawnEscape,spawnEscapeError
syntax keyword spawnTodo TODO FIXME NOTE HACK XXX contained
syntax match spawnComment '//.*$' contains=spawnTodo,@Spell
syntax match spawnDocComment '///.*$' contains=spawnTodo,@Spell

highlight default link spawnConditional Conditional
highlight default link spawnStatement Statement
highlight default link spawnRepeat Repeat
highlight default link spawnStructure Structure
highlight default link spawnBoolean Boolean
highlight default link spawnConstant Constant
highlight default link spawnType Type
highlight default link spawnNumber Number
highlight default link spawnFunction Function
highlight default link spawnOperator Operator
highlight default link spawnDelimiter Delimiter
highlight default link spawnEscape SpecialChar
highlight default link spawnEscapeError Error
highlight default link spawnString String
highlight default link spawnTodo Todo
highlight default link spawnComment Comment
highlight default link spawnDocComment SpecialComment

let b:current_syntax = 'spawn'
