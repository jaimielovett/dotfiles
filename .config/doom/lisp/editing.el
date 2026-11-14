;;; editing.el -*- lexical-binding: t; -*-

(after! smartparens
  ;; Keep paired delimiters, but do not add a second newline when pressing RET.
  (dolist (pair '("(" "{" "["))
    (sp-local-pair '(c-mode c++-mode c-ts-mode c++-ts-mode)
                   pair nil
                   :post-handlers '(:rem ("||\n[i]" "RET")))))

(defun jam-trim-leading-blank-lines ()
  "Remove leading blank lines without changing the first code line's indent."
  (unless buffer-read-only
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-min))
        (skip-chars-forward " \t\r\n")
        (unless (eobp)
          (beginning-of-line))
        (delete-region (point-min) (point))))))

;; Run after the usual whitespace and formatting hooks.
(add-hook 'before-save-hook #'jam-trim-leading-blank-lines 90)
