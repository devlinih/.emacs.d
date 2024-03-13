;; init.el --- Devlin Ih's Emacs Init File -*- lexical-binding: t; -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; DO NOT EDIT THIS FILE DIRECTLY. ;;;;
;;;;     Edit Emacs.org Instead!     ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq gc-cons-threshold (* 100 1000 1000)) ; Set high for startup

(setq native-comp-async-report-warnings-errors nil
      native-comp-deferred-compilation t)

(when (and (>= emacs-major-version 28) (native-comp-available-p))
  (require 'comp)
  (native-compile-prune-cache))

(setq-default
 ;; Inhibit startup message
 inhibit-startup-message t
 inhibit-splash-screen t

 ;; Increase max recursion
 max-lisp-eval-depth (* max-lisp-eval-depth 5)

 ;; Increase maxx variable bindings
 max-specpdl-size (* max-specpdl-size 10)

 ;; Put all the customize crap in a different file
 custom-file "~/.emacs.d/custom-file.el"

 ;; Set frametitle to something practical (if you couldn't read the
 ;; modeline I guess)
 frame-title-format '("%b" " - " "Emacs")

 ;; No lockfiles because they are annoying
 create-lockfiles nil

 ;; spaces > tabs
 indent-tabs-mode nil

 ;; No autosave
 auto-save-default nil

 ;; Comands in minibuffers
 enable-recursive-minibuffers t

 ;; Ask before exiting
 confirm-kill-emacs 'y-or-n-p

 ;; Pixelwise resize to work with tiling wms
 frame-resize-pixelwise t

 ;; Stop the large file warning it's annoying
 large-file-warning-threshold nil

 ;; Tab completion for corfu and such
 tab-always-indent 'complete

 ;; Fill Column
 fill-column 79

 ;; Sentence ends with a single space
 sentence-end-double-space nil

 ;; Make kill ring even larger
 kill-ring-max 512)

;; Nvr mind I think I liked the default behavior.
;; scroll-conservatively 20)

;; Put all backup files in .emacs.d/backups/
(setq-default backup-by-copying t
              backup-directory-alist `(("." . ,(concat user-emacs-directory "backups"))))

(load "~/.emacs.d/lisp/dates.el")
(load "~/.emacs.d/lisp/buffer-file.el")

(when (file-exists-p "~/.emacs.d/machine-specific.el")
  (load "~/.emacs.d/machine-specific.el"))

(tool-bar-mode -1)   ; No tool bar
;; (scroll-bar-mode -1) ; No scroll bar
(menu-bar-mode -1)   ; Disable menu bar, turned back on if on Mac later
(tooltip-mode -1)    ; Disable tool tips
(column-number-mode) ; Display colum numbers in modeline
(show-paren-mode 1)  ; Highlight parenthesis

;; There is most certainly a better way of handling this than copying the
;; original definition the way I did

(defun dih/split-window-sensibly (&optional window)
  "Split WINDOW in a way suitable for `display-buffer'.

Redefined version that prefers splitting into two tall instead of
two wide."
  (let ((window (or window (selected-window))))
    (or (and (window-splittable-p window t)
             ;; Split window horizontally (two tall)
             (with-selected-window window
               (split-window-right)))
        (and (window-splittable-p window)
             ;; Split window vertically (two wide)
             (with-selected-window window
               (split-window-below)))
        (and
         ;; If WINDOW is the only usable window on its frame (it is
         ;; the only one or, not being the only one, all the other
         ;; ones are dedicated) and is not the minibuffer window, try
         ;; to split it vertically disregarding the value of
         ;; `split-height-threshold'.
         (let ((frame (window-frame window)))
           (or
            (eq window (frame-root-window frame))
            (catch 'done
              (walk-window-tree (lambda (w)
                                  (unless (or (eq w window)
                                              (window-dedicated-p w))
                                    (throw 'done nil)))
                                frame nil 'nomini)
              t)))
         (not (window-minibuffer-p window))
         (let ((split-height-threshold 0))
           (when (window-splittable-p window)
             (with-selected-window window
               (split-window-below))))))))

(setq-default
 split-height-threshold 60 ; don't split vertically if not at least 60 lines tall
 split-width-threshold 160) ; don't split horizontally if not at least 160 wide

;; Redefine the behavior of split-window-sensibly
(advice-add
 'split-window-sensibly
 :override
 'dih/split-window-sensibly)

;; Scroll half pages
(advice-add
 'scroll-down-command
 :around
 (lambda (orig-fun &rest args)
   (let ((next-screen-context-lines
          (max 1 (round (/ (window-screen-lines) 2)))))
     (apply orig-fun args))))
(advice-add
 'scroll-up-command
 :around
 (lambda (orig-fun &rest args)
   (let ((next-screen-context-lines
          (max 1 (round (/ (window-screen-lines) 2)))))
     (apply orig-fun args))))

(when (>= emacs-major-version 29)
  (pixel-scroll-precision-mode t)
  (setq pixel-scroll-precision-large-scroll-height 40.0
        pixel-scroll-precision-interpolate-page t)
  (defun dih/pixel-scroll-precision-scroll-down-command (&optional arg)
    "Smoothly scroll text of selected window down ARG lines.

If ARG is omitted or nil, scroll down by a near full screen.

My function to use pixel scrolling when M-v ing.
This is a hopefully temporary solution. Maybe I can contribute to upstream?"
    (interactive "^P")
    (let ((line-height (line-pixel-height)))
      (let* ((num-lines (or arg
                            (- (window-screen-lines) next-screen-context-lines)))
             (num-pixels (* num-lines line-height)))
        (pixel-scroll-precision-interpolate num-pixels
                                            (get-buffer-window)
                                            1))))

  (defun dih/pixel-scroll-precision-scroll-up-command (&optional arg)
    "Smoothly scroll text of selected window up ARG lines.

If ARG is omitted or nil, scroll upn by a near full screen.

My function to use pixel scrolling when C-v ing.
This is a hopefully temporary solution. Maybe I can contribute to upstream?"
    (interactive "^P")
    (let ((num-lines (or arg
                         (- (window-screen-lines) next-screen-context-lines))))
      (dih/pixel-scroll-precision-scroll-down-command (- num-lines))))

  (define-key (current-global-map)
              [remap scroll-down-command]
              'dih/pixel-scroll-precision-scroll-down-command)
  (define-key (current-global-map)
              [remap scroll-up-command]
              'dih/pixel-scroll-precision-scroll-up-command))

(when (>= emacs-major-version 29)
  (advice-add
   'dih/pixel-scroll-precision-scroll-up-command
   :around
   (lambda (orig-fun &rest args)
     (let ((next-screen-context-lines (max 1
                                           (/ (round (window-screen-lines)) 2)))
           (pixel-scroll-precision-interpolation-total-time .3))
       (apply orig-fun args))))
  (advice-add
   'dih/pixel-scroll-precision-scroll-down-command
   :around
   (lambda (orig-fun &rest args)
     (let ((next-screen-context-lines (max 1
                                           (/ (round (window-screen-lines)) 2)))
           (pixel-scroll-precision-interpolation-total-time .3))
       (apply orig-fun args))))
  (advice-add
   'pixel-scroll-interpolate-down
   :around
   (lambda (orig-fun &rest args)
     (let ((pixel-scroll-precision-interpolation-total-time .5))
       (apply orig-fun args))))
  (advice-add
   'pixel-scroll-interpolate-up
   :around
   (lambda (orig-fun &rest args)
     (let ((pixel-scroll-precision-interpolation-total-time .5))
       (apply orig-fun args)))))

(global-set-key (kbd "C-z") nil)

(global-set-key (kbd "M-o") 'other-window)

(global-set-key (kbd "C-c c") 'comment-or-uncomment-region)

(require 'cl-lib)

(cl-case system-type
  ;; Add other systems as needed
  (darwin (setq mac-command-modifier 'meta
                mac-option-modifier 'super
                mac-control-modifier 'control
                ns-function-modifier 'hyper)
          (menu-bar-mode)))

(setq dih/hardware-arch
      (car (split-string system-configuration "-")))

(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/")))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(unless (package-installed-p 'use-package)
  (if package-enable-at-startup
      (package-install "use-package")
    (straight-use-package 'use-package)))

;; It's in straight instead of use-package, huh
(use-package straight
  :custom
  (straight-use-package-by-default t))

(use-package org
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda))
  :config
  (setq org-directory "~/Org")

  (setq org-ellipsis " ▾") ; Replace the ... on collapsed headers

  (setq org-agenda-start-with-log-mode t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)

  (setq org-agenda-files
        '("~/Org"))

  (plist-put org-format-latex-options :scale 1.5) ; Make LaTeX previews bigger

  :hook
  ((org-mode . org-indent-mode)))

(with-eval-after-load 'org
  (require 'org-tempo)

  (add-to-list 'org-structure-template-alist '(el . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '(mat . "src matlab"))
  (add-to-list 'org-structure-template-alist '(oct . "src octave"))
  (add-to-list 'org-structure-template-alist '(py . "src python"))
  (add-to-list 'org-structure-template-alist '(pyfile . "src python :results file"))
  (add-to-list 'org-structure-template-alist '(cl . "src lisp"))
  (add-to-list 'org-structure-template-alist '(ml . "src ocaml"))
  (add-to-list 'org-structure-template-alist '(cpp . "src c++"))
  (add-to-list 'org-structure-template-alist '(rv . "src riscv"))

  ;; Not for code, I think <q works but whatever
  (add-to-list 'org-structure-template-alist '(quote . "quote")))

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (lisp . t)
     (python . t)
     (ocaml . t)))
  (setq org-babel-lisp-eval-fn #'sly-eval
        org-confirm-babel-evaluate nil)
  (push '("conf-unix" . conf-unix) org-src-lang-modes))

;; Automatically tangle our Emacs.org config file when we save it
(defun config/org-babel-tangle-config ()
  (when (string-equal (file-name-directory (buffer-file-name))
                      (expand-file-name "~/.emacs.d/"))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'after-save-hook #'config/org-babel-tangle-config)))

(require 'ox-latex)

(add-to-list 'org-latex-packages-alist
             '("skip=10pt plus1pt, indent=0em" "parskip" nil))

;; URLs should break on hyphens
(add-to-list 'org-latex-packages-alist "\\PassOptionsToPackage{hyphens}{url}")

;; Disable the automatic insertion of hypersetup
(customize-set-value
   'org-latex-hyperref-template
   "\\hypersetup{
linktoc=all,
colorlinks=true,
urlcolor=DeepSkyBlue1
}
")

;; Add xcolor to included packages
(add-to-list 'org-latex-packages-alist "\\usepackage[x11names]{xcolor}")

;; Allows using Emacs' syntax highlighting in pdf exports!
(use-package engrave-faces)

;; xelatex
(setq org-latex-compiler "xelatex")

;; Syntax highlighting
(setq org-latex-src-block-backend 'engraved)
;; org-latex-engraved-theme "need a good light theme")

;; Geometry
(add-to-list 'org-latex-packages-alist
             '("" "geometry" nil))

;; Smart quotes
(setq org-export-with-smart-quotes t)

;; Beamer export, for additional info see https://github.com/fniessen/refcard-org-beamer
(eval-after-load "ox-latex"

  ;; update the list of LaTeX classes and associated header (encoding, etc.)
  ;; and structure
  '(add-to-list 'org-latex-classes
                `("beamer"
                  ,(concat "\\documentclass[presentation]{beamer}\n"
                           "[DEFAULT-PACKAGES]"
                           "[PACKAGES]"
                           "[EXTRA]\n")
                  ("\\section{%s}" . "\\section*{%s}")
                  ("\\subsection{%s}" . "\\subsection*{%s}")
                  ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))

;; Taken from stack exchange
;; https://emacs.stackexchange.com/questions/3374/set-the-background-of-org-exported-code-blocks-according-to-theme
(defun my/org-inline-css-hook (exporter)
  "Insert custom inline css to automatically set the
background of code to whatever theme I'm using's background"
  (when (eq exporter 'html)
    (let* ((my-pre-bg (face-background 'default))
           (my-pre-fg (face-foreground 'default)))
      (setq
       org-html-head-extra
       (concat
        org-html-head-extra
        (format "<style type=\"text/css\">\n pre.src {background-color: %s; color: %s;}</style>\n"
                my-pre-bg my-pre-fg))))))

(with-eval-after-load 'org
  (add-hook 'org-export-before-processing-hook 'my/org-inline-css-hook))

(use-package htmlize)

(use-package org-mime
  :config
  (setq org-mime-export-options '(:section-numbers nil
                                  :with-author nil
                                  :with-toc nil))
  ;; dark background for code blocks
  (add-hook 'org-mime-html-hook
            (lambda ()
              (org-mime-change-element-style
               "pre" (format "color: %s; background-color: %s; padding: 0.5em;"
                             "#ebdbb2" "#282828"))))

  ;; offset blockquotes
  (add-hook 'org-mime-html-hook
            (lambda ()
              (org-mime-change-element-style
               "blockquote" "border-left: 2px solid gray; padding-left: 4px;")))

  ;; Confirm sending non-html mail
  (add-hook 'message-send-hook 'org-mime-confirm-when-no-multipart))

(use-package citeproc
  :after org)

(use-package org-fragtog
  :after org
  :hook (org-mode . org-fragtog-mode))

(use-package all-the-icons
  :if (display-graphic-p))

;; (when (>= emacs-major-version 29)
;;   (set-frame-parameter nil 'alpha-background 90)
;;   (add-to-list 'default-frame-alist '(alpha-background . 90)))

(setq custom-safe-themes t) ; Trust all themes

(use-package gruvbox-theme)

;; Rainbow delimiters
(defun my/set-rainbow-delimiters-gruvbox ()
  (with-eval-after-load 'rainbow-delimiters
    (set-face-attribute 'rainbow-delimiters-depth-1-face nil
                        :foreground "#cc241d") ; Red
    (set-face-attribute 'rainbow-delimiters-depth-2-face nil
                        :foreground "#fabd2f") ; Yellow
    (set-face-attribute 'rainbow-delimiters-depth-3-face nil
                        :foreground "#98971a") ; Green
    (set-face-attribute 'rainbow-delimiters-depth-4-face nil
                        :foreground "#689d6a") ; Aqua
    (set-face-attribute 'rainbow-delimiters-depth-5-face nil
                        :foreground "#458588") ; Blue
    (set-face-attribute 'rainbow-delimiters-depth-6-face nil
                        :foreground "#b16286") ; Purple
    (set-face-attribute 'rainbow-delimiters-depth-7-face nil
                        :foreground "#a89984") ; FG darkened
    (set-face-attribute 'rainbow-delimiters-depth-8-face nil
                        :foreground "#ebdbb2") ; FG
    (set-face-attribute 'rainbow-delimiters-unmatched-face nil
                        :background "#665c54"
                        :foreground "#fdf4c1")))

(load-theme 'gruvbox-dark-medium)
(my/set-rainbow-delimiters-gruvbox)

(use-package solo-jazz-theme
  :disabled)
;; (load-theme 'solo-jazz)

(use-package mood-line
  :custom-face
  ;; Buffer name
  ;; (mode-line-buffer-id ((t (:weight bold ))))
  :config
  ;; Enable
  (setq mood-line-glyph-alist mood-line-glyphs-fira-code)
  (mood-line-mode))

(use-package smart-mode-line
  :disabled
  :config
  (sml/setup)

  :custom-face
  (sml/line-number ((t (:inherit sml/modes :weight bold))))
  (sml/col-number ((t (:inherit sml/line-number))))
  ;; In the newer Emacs branch they make the modeline use the variable pitch
  ;; font by default. I hate that because I have my variable pitch font set
  ;; larger and it looked really stupid.
  (mode-line-active ((t (:inherit mode-line)))))

(use-package diminish)

(use-package aas
  :hook (LaTeX-mode . aas-activate-for-major-mode)
  :hook (org-mode . aas-activate-for-major-mode)
  :hook (aas-mode . yas-minor-mode))

(use-package laas
  :hook (LaTeX-mode . laas-mode)
  :hook (org-mode . laas-mode)
  :config
  (aas-set-snippets 'laas-mode
    "\\begin" (lambda () (interactive)
                (yas-expand-snippet "\\begin{$1}\n$0\n\\end{$1}\n"))
    "$$" (lambda () (interactive)
           (yas-expand-snippet "\\$$1\\$"))

    :cond #'texmathp ; expand only while in math
    ;; bind to functions!
    "Sum" (lambda () (interactive)
            (yas-expand-snippet "\\sum_{$1}^{$2} $0"))
    "text" (lambda () (interactive)
             (yas-expand-snippet "\\text{$1}$0"))
    "left(" (lambda () (interactive)
              (yas-expand-snippet "\\left( $1 \\right)$0"))
    "left[" (lambda () (interactive)
              (yas-expand-snippet "\\left[ $1 \\right]$0"))
    "left{" (lambda () (interactive)
              (yas-expand-snippet "\\left\\\\{ $1 \\right\\\\}$0"))
    "left|" (lambda () (interactive)
              (yas-expand-snippet "\\left| $1 \\right|$0"))

    ;; add accent snippets
    :cond #'laas-object-on-left-condition
    "qq" (lambda () (interactive) (laas-wrap-previous-object "sqrt"))))

;; Find ideal set of arguments for aspell
;; Taken from http://blog.binchen.org/posts/what-s-the-best-spell-check-set-up-in-emacs/
(defun config/flyspell-detect-ispell-args (&optional run-together)
  "if RUN-TOGETHER is true, spell check the CamelCase words."
  (let (args)
    (cond
     ((string-match  "aspell$" ispell-program-name)
      ;; Force the English dictionary for aspell
      ;; Support Camel Case spelling check (tested with aspell 0.6)
      (setq args (list "--sug-mode=ultra" "--lang=en_US")))
      ;; (when run-together
     ;;    (cond
     ;;     ;; Kevin Atkinson said now aspell supports camel case directly
     ;;     ;; https://github.com/redguardtoo/emacs.d/issues/796
     ;;     ((string-match-p "--camel-case"
     ;;                      (shell-command-to-string (concat ispell-program-name " --help")))
     ;;      (setq args (append args '("--camel-case"))))

     ;;     ;; old aspell uses "--run-together". Please note we are not dependent on this option
     ;;     ;; to check camel case word. wucuo is the final solution. This aspell options is just
     ;;     ;; some extra check to speed up the whole process.
     ;;     (t
     ;;      (setq args (append args '("--run-together" "--run-together-limit=16")))))))

     ((string-match "hunspell$" ispell-program-name
       ;; Force the English dictionary for hunspell
       (setq args "-d en_US"))))
    args))

;; Disable camlCase when correcting a word
;; (defun config/ispell-word-hack (orig-func &rest args)
;;   "Use Emacs original arguments when calling `ispell-word'.
;; When fixing a typo, avoid pass camel case option to cli program."
;;   (let* ((old-ispell-extra-args ispell-extra-args))
;;     (ispell-kill-ispell t)
;;     ;; use emacs original argument
;;     (setq ispell-extra-args (config/flyspell-detect-ispell-args))
;;     (apply orig-func args)
;;     ;; restore our own ispell arguments
;;     (setq ispell-extra-args old-ispell-extra-args)
;;     (ispell-kill-ispell t)))

;; (defun config/flyspell-text-mode-hook-setup ()
;;   ;; Turn off RUN-TOGETHER option when spell check text-mode
;;   (setq-local ispell-extra-args (config/flyspell-detect-ispell-args)))

(use-package flyspell
  :straight nil
  :config
  (setq ispell-program-name "aspell")
  ;; Set arguments to pass to aspell
  (setq-default ispell-extra-args (config/flyspell-detect-ispell-args t))
  ;; Setup hack for correcting words (no caml case checking)
  ;; Taken fron the blog post again
  ;; (advice-add 'ispell-word :around #'config/ispell-word-hack)
  ;; (advice-add 'flyspell-auto-correct-word :around #'config/ispell-word-hack)
  :hook
  ((text-mode . flyspell-mode)
   ;; (text-mode . config/flyspell-text-mode-hook-setup)
   (prog-mode . flyspell-prog-mode)))

(when (file-exists-p "~/.emacs.d/email-config.el")
  (load "~/.emacs.d/email-config.el"))

(use-package visual-fill-column
  :diminish
  :hook ((text-mode . visual-line-mode)
         (text-mode . visual-fill-column-mode)
         (ein:notebook-mode . visual-fill-column-mode))
  :custom
  (visual-fill-column-enable-sensible-window-split t)
  (visual-fill-column-width 90)
  (visual-fill-column-center-text t)
  (visual-fill-column-fringes-outside-margins nil))

(use-package tex
  :straight auctex
  :hook ((LaTeX-mode . LaTeX-math-mode))
  :config
  (setq TeX-source-correlate-mode t)
  (setq TeX-source-correlate-method 'synctex)
  (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
        TeX-source-correlate-start-server t)
  (setq TeX-parse-self t)
  (setq TeX-auto-save t))

(use-package markdown-mode
  :hook ((markdown-mode . auto-fill-mode))
  :custom
  ;; Syntax highlighting in Markdown (way better than polymode which breaks
  ;; with tree sitter (at least the old 28- version)
  ((markdown-fontify-code-blocks-natively t)))

(use-package edit-indirect)

(use-package quarto-mode
  :disabled)

(use-package deadgrep)

(use-package vdiff
  :bind
  (:map vdiff-mode-map
        ("C-c h" . vdiff-hydra/body)))
;; :config)
;; (define-key vdiff-mode-map (kbd "C-c") vdiff-mode-prefix-map))

(use-package diffview)

(use-package tramp
  :straight nil
  :custom
  ;; Use controlmaster options in ~/.ssh/ instead
  ((tramp-use-ssh-controlmaster-options . nil))
  :config
  ;; Disable VC, makes TRAMP way faster (and I think project.el does it still)
  ;; (setq vc-ignore-dir-regexp
  ;;                   (format "\\(%s\\)\\|\\(%s\\)"
  ;;                           vc-ignore-dir-regexp
  ;;                           tramp-file-name-regexp))
  ;; I think lsp-mode said to add this but I'm not sure
  (add-to-list 'tramp-remote-path 'tramp-own-remote-path))

(use-package dired
  :straight nil
  :bind (("C-c j" . dired-jump))
  ;; Disable dired single because it makes dired over TRAMP unbearable
  ;; :map dired-mode-map ; Let's not repeat not being able to type b...
  ;; ("f" . dired-single-buffer)
  ;; ("b" . dired-single-up-directory)
  ;; ("h" . dired-hide-dotfiles-mode)
  ;; ("<RET>" . dired-single-buffer))
  :custom ((dired-listing-switches "-alh --group-directories-first")))

(use-package dired-single
  :disabled)

(use-package dired-hide-dotfiles
  :hook (dired-mode . dired-hide-dotfiles-mode))

(use-package diredfl
  :config (diredfl-global-mode))

(use-package dired-open
  :config
  (setq dired-open-extensions '(("mp4" . "mpv")
                                ("mkv" . "mpv")
                                ("mov" . "mpv")
                                ("webm" . "mpv"))))

(use-package disk-usage)

(use-package helpful
  :defer t
  :bind
  ([remap describe-function] . helpful-callable)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-key] . helpful-key))

(use-package auth-source-pass
  :init (auth-source-pass-enable)
  :config
  (setq auth-sources '(password-store)))

(use-package pass)

(require 'epa-file)
;; (setq epa-pinentry-mode 'loopback)

(use-package pdf-tools
  :config
  (pdf-tools-install t t)) ; This might not work if it isn't installed yet.

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.5))

(use-package whitespace-cleanup-mode
  :diminish
  :config
  (global-whitespace-cleanup-mode))

(clear-abbrev-table global-abbrev-table)

(define-abbrev-table 'global-abbrev-table
  '(
    ;; Dates
    ("td" "" dih/insert-date-iso)
    ("tdus" "" dih/insert-date-usa-short)
    ("tdusl" "" dih/insert-date-usa-long)

    ;; If these could contain punctuation that would be awesome because I
    ;; could do some LaTeX symbols

    ;; End
    ))

(setq-default abbrev-mode nil ;; change this to use hooks
              save-abbrevs nil)

(diminish 'abbrev-mode)

(use-package orderless
  :custom (completion-styles '(orderless)))

(use-package savehist
  :init
  (savehist-mode))

(use-package vertico
  :init
  (vertico-mode)

  ;; Create a keybinding for up to point tab completion
  (define-key vertico-map (kbd "M-TAB") #'minibuffer-complete))

;; Enable richer annotations using the Marginalia package
(use-package marginalia
  ;; Either bind `marginalia-cycle` globally or only in the minibuffer
  :bind (; ("M-A" . marginalia-cycle)
         :map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  :init
  (marginalia-mode))

;; Example config, I need to tweak. This is something I will deal with later^{TM}
(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)

         ;; Isearch integration (actually Isearch gets replaced)
         ("M-s e" . consult-isearch-history)
         ;; Use consult-line instead of isearch for most cases
         ("C-s" . consult-line)
         ("C-r" . consult-line)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         :map pdf-view-mode-map ;; pdftools, don't use consult line bad things happen
         ("C-s" . isearch-forward)
         ("C-r" . isearch-backward)
         ("M-g M-g" . pdf-view-goto-page)
         ("M-g g" . pdf-view-goto-page)
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<")) ;; "C-+"

;; Optionally make narrowing help available in the minibuffer.
;; You may want to use `embark-prefix-help-command' or which-key instead.
;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

;; By default `consult-project-function' uses `project-root' from project.el.
;; Optionally configure a different project root function.
  ;;;; 1. project.el (the default)
;; (setq consult-project-function #'consult--default-project--function)
  ;;;; 2. vc.el (vc-root-dir)
;; (setq consult-project-function (lambda (_) (vc-root-dir)))
  ;;;; 3. locate-dominating-file
;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
  ;;;; 4. projectile.el (projectile-project-root)
;; (autoload 'projectile-project-root "projectile")
;; (setq consult-project-function (lambda (_) (projectile-project-root)))
  ;;;; 5. No project support
;; (setq consult-project-function nil)

(use-package corfu
  :bind
  ;; Configure SPC for separator insertion
  (:map corfu-map ("SPC" . corfu-insert-separator))
  :custom
  ;; Enable autocompletion with corfu
  (corfu-auto t)
  (corfu-auto-prefix 4)
  (corfu-auto-delay 0)
  (corfu-quit-no-match t)
  :init
  (global-corfu-mode))

(defun my/force-capfs ()
  "Run this function in hooks for other modes to force the capfs"

  ;; Add `completion-at-point-functions', used by `completion-at-point'.
  (add-to-list 'completion-at-point-functions #'cape-file)
  ;; (add-to-list 'completion-at-point-functions #'cape-tex)
  ;; (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  ;; (add-to-list 'completion-at-point-functions #'cape-keyword)

  ;;(add-to-list 'completion-at-point-functions #'cape-sgml)
  ;;(add-to-list 'completion-at-point-functions #'cape-rfc1345)
  ;;(add-to-list 'completion-at-point-functions #'cape-abbrev)
  ;;(add-to-list 'completion-at-point-functions #'cape-ispell)
  ;;(add-to-list 'completion-at-point-functions #'cape-dict)
  ;;(add-to-list 'completion-at-point-functions #'cape-symbol)
  ;;(add-to-list 'completion-at-point-functions #'cape-line)
  )

;; Default config
(use-package cape
  ;; Bind dedicated completion commands
  :bind (("C-c p p" . completion-at-point) ;; capf
         ("C-c p t" . complete-tag)        ;; etags
         ("C-c p d" . cape-dabbrev)        ;; or dabbrev-completion
         ("C-c p f" . cape-file)
         ("C-c p k" . cape-keyword)
         ("C-c p s" . cape-symbol)
         ("C-c p a" . cape-abbrev)
         ("C-c p i" . cape-ispell)
         ("C-c p l" . cape-line)
         ("C-c p w" . cape-dict)
         ("C-c p \\" . cape-tex)
         ("C-c p _" . cape-tex)
         ("C-c p ^" . cape-tex)
         ("C-c p &" . cape-sgml)
         ("C-c p r" . cape-rfc1345))
  :hook
  ((text-mode . my/force-capfs)
   (prog-mode . my/force-capfs)
   (conf-mode . my/force-capfs)))

;; A few more useful configurations...
(use-package emacs
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; Alternatively try `consult-completing-read-multiple'.
  (defun crm-indicator (args)
    (cons (concat "[CRM] " (car args)) (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

(use-package eldoc
  :custom
  (eldoc-idle-delay 0))

(use-package rainbow-delimiters
  :custom
  (rainbow-delimiters-max-face-count 8)
  :hook
  ((prog-mode . rainbow-delimiters-mode)
   (matlab-mode . rainbow-delimiters-mode)))

(use-package rainbow-mode
  :diminish)

(use-package magit
  :bind
  (("C-x g" . magit-status)
   ("C-x p m" . magit-project-status)))

(use-package forge
  :after magit)

(use-package yasnippet
  :config
  (setq yas-snippet-dirs (cons (concat user-emacs-directory "my-snippets")
                               yas-snippet-dirs))

  :bind
  (("C-c s" . yas-insert-snippet)))

(use-package treesit-auto
  :if (>= emacs-major-version 29)
  :config
  ;; Uncomment to automatically install, or use M-x treesit-auto-install-all
  ;; (setq treesit-auto-install t)
  (global-treesit-auto-mode))

(use-package tree-sitter
  :if (< emacs-major-version 29)
  :diminish
  :config
  (global-tree-sitter-mode)
  :hook
  (tree-sitter-mode . tree-sitter-hl-mode))

(use-package tree-sitter-langs
  :if (< emacs-major-version 29))

(use-package origami)

(use-package eglot)

(use-package lsp-mode
  ;; :commands (lsp lsp-deferred)
  :disabled
  :custom
  ((lsp-completion-provider :none) ;; Use default/Corfu
   ;; Breadcrumb is useful on large projects but annoying on small ones
   ;; (lsp-headerline-breadcrumb-enable nil)
   (lsp-headerline-breadcrumb-enable t)
   (lsp-signature-render-documentation nil))
  :init
  (setq lsp-keymap-prefix "C-l")

  ;; Configure orderless using the suggested basic config.
  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
          '(orderless)))
  :hook
  ((lsp-completion-mode . my/lsp-mode-setup-completion)
   (lsp-mode . yas-minor-mode))
  :config
  (lsp-enable-which-key-integration t))

(use-package ein
  :custom
  (ein:output-area-inlined-images t))

(use-package license-templates)

(use-package apheleia)

(use-package parinfer-rust-mode
  ;; Only install on compatible architectures
  ;; :if (member dih/hardware-arch '("x86_64"))
  :diminish
  :custom
  (parinfer-rust-dim-parens nil) ;; Disable as to not break src exports
  ;; (parinfer-rust-auto-download t)
  :hook
  emacs-lisp-mode
  lisp-mode
  racket-mode)

(use-package sly
  :config
  (setq inferior-lisp-program "sbcl"))

(use-package sly-quicklisp)

(use-package racket-mode
  :disabled)
  ;; :config
  ;; (require 'lsp)
  ;; (lsp-register-client
  ;;  (make-lsp-client :new-connection
  ;;                   (lsp-stdio-connection
  ;;                    '("racket" "-l" "racket-langserver"))
  ;;                   :major-modes '(racket-mode)
  ;;                   :server-id 'racket-langserver)))

(use-package cc-mode
    :init
    (defconst dih-c-style
      '("gnu"
        (c-basic-offset . 4)
        (c-offsets-alist . ((innamespace . [0])))))
                            ;; (case-label . +)))))
    (c-add-style "dih" dih-c-style)
    (setq c-default-style '((java-mode . "java")
                            (awk-mode . "awk")
                            (other . "dih")))
    :bind
    (:map c-mode-base-map
     ;; Why does it rebind that?
     ("<tab>" . indent-for-tab-command)))

(use-package clang-format)

(use-package cmake-mode)

(use-package go-mode
  :disabled)

(use-package haskell-mode
  :disabled)

;; (add-to-list 'auto-mode-alist '("\\.m\\'" . octave-mode))

(use-package matlab
  :disabled
  :config
  (add-to-list
   'auto-mode-alist
   '("\\.m\\'" . matlab-mode)))

(add-to-list 'auto-mode-alist '("\\PKGBUILD\\'" . sh-mode))

(use-package pyvenv
  :init
  (setenv "WORKON_HOME" "~/.pyenv/versions"))

(use-package poetry
  :config
  (poetry-tracking-mode))
;;:custom)
;;((poetry-tracking-strategy . 'switch-buffer)))

(use-package yaml-mode)

(use-package tuareg
  :disabled)

(use-package ocamlformat
  :disabled
  :custom
  (ocamlformat-enable 'enable-outside-detected-project)
  :hook
  (before-save . ocamlformat-before-save))

(use-package ocp-indent)

(use-package utop
  :bind (:map utop-mode-map
              ("<tab>" . indent-for-tab-command)))

(use-package dune)

(add-to-list 'auto-mode-alist '("\\.ino\\'" . c++-mode))

(with-eval-after-load 'verilog-mode
  (setq dih/navigation-verilog-mode-syntax-table
        (make-syntax-table verilog-mode-syntax-table))
  (modify-syntax-entry ?_ "_" dih/navigation-verilog-mode-syntax-table)

  (defun dih/verilog-forward-word (&optional arg)
    (interactive "p")
    (with-syntax-table dih/navigation-verilog-mode-syntax-table
      (forward-word arg)))

  (defun dih/verilog-backward-word (&optional arg)
    (interactive "p")
    (with-syntax-table dih/navigation-verilog-mode-syntax-table
      (backward-word arg))))

(use-package verilog-mode
  :custom
  ((verilog-auto-newline . nil)
   (verilog-case-fold . nil))
  ;; (verilog-auto-arg-sort . t))
  :bind
  (:map verilog-mode-map
        ("M-f" . dih/verilog-forward-word)
        ("M-b" . dih/verilog-backward-word))
  :config
  ;; Because it complains about t not being a list
  (setq verilog-auto-arg-sort t)
  (add-to-list 'verilog-library-directories "..")
  (add-to-list 'verilog-library-directories "../hdl"))

(use-package verilog-ext
  :hook ((verilog-mode . verilog-ext-mode))
  :init
  ;; Can also be set through `M-x RET customize-group RET verilog-ext':
  ;; Comment out/remove the ones you do not need
  (setq verilog-ext-feature-list
        '(font-lock
          xref
          capf
          hierarchy
          eglot
          lsp
          flycheck
          beautify
          navigation
          template
          formatter
          compilation
          imenu
          which-func
          hideshow
          typedefs
          time-stamp
          block-end-comments
          ports))
  (setq verilog-ext-tags-backend 'tree-sitter)
  (setq verilog-ts-indent-level 3)
  :config
  (verilog-ext-mode-setup))

(use-package fpga
  :init
  (setq fpga-feature-list '(xilinx)))

(use-package riscv-mode)

(use-package lorem-ipsum)

(put 'narrow-to-region 'disabled nil) ; Region narrowing is useful

(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(setq gc-cons-threshold (* 20 1000 1000))

(if (>= 29 emacs-major-version)
    (setq use-short-answers t)
  (fset 'yes-or-no-p 'y-or-n-p))
