;; fix-fonts-daemon.el --- Fix fonts when starting Emacs daemon -*- lexical-binding: t; -*-

;; When starting Emacs with `emacs --daemon`, the `set-face-attribute' calls in
;; my machine specific config do nothing because there is no active frame. Run
;; this file with `emacsclient -c -e '(load "/path/to/this/file.el")' to fix
;; it.

(load (f-join user-emacs-directory "machine-specific.el"))
(delete-frame)
