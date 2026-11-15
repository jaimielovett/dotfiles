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

(defun jam-c-newline ()
  "Insert one indented code line, splitting an empty brace pair if needed."
  (interactive)
  (let ((smartparens-mode nil)
        (electric-indent-inhibit t)
        (split-braces (and (eq (char-before) ?{)
                           (looking-at-p "[ \t]*}"))))
    (newline)
    (when split-braces
      (save-excursion
        (newline)
        (indent-according-to-mode)))
    (indent-according-to-mode)))

(defun jam-c-setup-enter ()
  "Use predictable Enter behavior in C and C++ buffers."
  (local-set-key (kbd "RET") #'jam-c-newline)
  (when (fboundp 'evil-local-set-key)
    (evil-local-set-key 'insert (kbd "RET") #'jam-c-newline)))

(dolist (hook '(c-mode-hook c++-mode-hook c-ts-mode-hook c++-ts-mode-hook))
  (add-hook hook #'jam-c-setup-enter))

;; Apply to already-open buffers when reloading Doom.
(dolist (buffer (buffer-list))
  (with-current-buffer buffer
    (when (memq major-mode '(c-mode c++-mode c-ts-mode c++-ts-mode))
      (jam-c-setup-enter))))
