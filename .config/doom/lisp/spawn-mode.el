;;; spawn-mode.el --- Syntax highlighting for Spawn -*- lexical-binding: t; -*-

(require 'prog-mode)

(defvar spawn-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?/ ". 12" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?\r ">" table)
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\\ "\\" table)
    table)
  "Syntax table for Spawn strings and // line comments.")

(defconst spawn-font-lock-keywords
  `((,(regexp-opt '("if" "else" "return" "struct" "while" "for") 'symbols)
     . font-lock-keyword-face)
    (,(regexp-opt '("auto" "bool" "string" "void"
                   "i8" "i16" "i32" "i64" "u8" "u16" "u32" "u64"
                   "f32" "f64") 'symbols) . font-lock-type-face)
    (,(regexp-opt '("true" "false" "uninit") 'symbols)
     . font-lock-constant-face)
    ("\\_<[0-9]+\\(?:\\.[0-9]+\\)?\\_>" . font-lock-constant-face)
    ("\\_<\\([A-Za-z_][A-Za-z0-9_]*\\)\\s-*::\\s-*("
     1 font-lock-function-name-face)
    ("\\_<\\([A-Za-z_][A-Za-z0-9_]*\\)\\s-*:[^:=]"
     1 font-lock-variable-name-face))
  "Highlighting for Spawn's documented syntax, including planned constructs.")

;;;###autoload
(define-derived-mode spawn-mode prog-mode "Spawn"
  "Major mode for Spawn source files.
Provides syntax highlighting and line comments; no compiler integration."
  :syntax-table spawn-mode-syntax-table
  (setq-local font-lock-defaults '(spawn-font-lock-keywords))
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local indent-tabs-mode nil)
  (setq-local tab-width 4))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.spawn\\'" . spawn-mode))

(provide 'spawn-mode)
;;; spawn-mode.el ends here
