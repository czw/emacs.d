;;; init.el -*- lexical-binding: t; -*-

;;; --- Package handling and settings file locations --------------------------
;; Package configuration as well as use-package
(eval-when-compile
  (require 'package)
  (when (version< emacs-version "28")
    (add-to-list 'package-archives
                 '("nongnu" . "https://elpa.nongnu.org/nongnu/")))
  (add-to-list 'package-archives
               '("melpa" . "https://melpa.org/packages/"))
  (package-initialize)
  (unless (package-installed-p 'use-package)
    (package-refresh-contents)
    (package-install 'use-package))
  (require 'use-package)
  (setq use-package-always-ensure t))

;; Keep my Emacs directory as clean as possible
(use-package no-littering)

;; Load custom configuration here
(setq custom-file (no-littering-expand-etc-file-name "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;;; --- General Emacs and editing setup ---------------------------------------
(setq-default
 fill-column 79                ; I work in a few 80-column environments
 indent-tabs-mode nil          ; Prefer spaces to tabs
 require-final-newline t       ; All files should end with a newline
 sentence-end-double-space nil ; Sentences end with a single space where I live
 use-short-answers t           ; y/n instead of yes/no

 ;; Silence startup message, I know about GNU Emacs already
 initial-scratch-message nil
 inhibit-startup-message t

 ;; Make backups of modified files in a separate directory
 delete-old-versions t
 vc-make-backup-files t
 version-control t)

;; We really like UTF-8 around here
(set-language-environment   "UTF-8")
(prefer-coding-system       'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(setq-default default-buffer-file-coding-system 'utf-8)

;; Support .editorconfig files
(use-package editorconfig
  :config
  (editorconfig-mode 1))

;; Do a few good cleanup tasks when saving
(defun czw/before-save-hook ()
  (copyright-update)
  (delete-trailing-whitespace)
  (executable-make-buffer-file-executable-if-script-p))
(add-hook 'before-save-hook 'czw/before-save-hook)

;; Configure spell checking
(setq-default ispell-program-name "aspell")

;; When compilation is ordered, save modified files and abort any currently
;; running compilation. Close the buffer automatically when done unless it
;; fails.
(setq-default
 compilation-always-kill t
 compilation-ask-about-save nil
 compilation-scroll-output t)
(winner-mode 1)
(setq compilation-finish-functions 'compile-autoclose)
(defun compile-autoclose (buffer string)
  (cond ((string-match "finished" string)
         (bury-buffer "*compilation*")
         (winner-undo)
         (message "Build successful"))
        (t
         (message "Compilation exited abnormally: %s" string))))

;; --- User interface things --------------------------------------------------
;; This is me!
(setq-default user-full-name "Jens Bäckman"
              user-mail-address "jens.backman@me.com")

(setq-default column-number-mode t) ; Show line and column in the mode bar

;; Modify some keyboard thingies when we're using macOS
(when (eq system-type 'darwin)
  (global-set-key [kp-delete] 'delete-char) ; fn-delete == right-delete
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none))

;; Enable Doom modeline and automatically switch between Solarized dark/light
(use-package all-the-icons)
(use-package doom-modeline
  :hook (after-init . doom-modeline-mode))
(use-package doom-themes)
(use-package auto-dark
  :init
  (setq auto-dark-dark-theme 'doom-solarized-dark)
  (setq auto-dark-light-theme 'doom-solarized-light)
  (auto-dark-mode t))

;; In order to help me explore and verify key bindings, I'm using which-key.
;; As soon as I press a key binding like C-c and wait for a while, a panel
;; will appear and display all bindings under that prefix and which command
;; they run.
(use-package which-key
  :config
  (which-key-mode))

;;; --- Various useful packages for navigation, editing and general work ------
;; Git support through the excellent Magit package
(use-package magit
  :bind
  (("C-x g" . magit-status)
   ("C-x C-g" . magit-diff-unstaged))
  :custom
  (git-commit-fill-column 72))

;; We have two separate completion frameworks: Corfu which operates in buffers
;; and Vertico which handles the minibuffer. Both use Orderless for advanced
;; completion ordering and Savehist for remembering what's been used most
;; recently.
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides
   '((file (styles basic partial-completion)))))
(use-package corfu
  :hook ((after-init . global-corfu-mode)
         (after-init . corfu-history-mode)
         (after-init . corfu-popupinfo-mode))
  :custom (corfu-auto t))
(use-package vertico
  :hook (after-init . vertico-mode))
(use-package savehist
  :hook (after-init . savehist-mode)
  :custom
  (add-to-list 'savehist-additional-variables 'corfu-history))

;; Projectile handles common tasks when working with projects: opening project
;; directories, finding project files, compiling, running tests, switching
;; between cpp/h files and many more things.
(use-package projectile
  :bind-keymap ("C-c p" . projectile-command-map)
  :hook (after-init . projectile-mode)
  :config
  ;; Add custom commands for CMake projects
  (projectile-register-project-type
   'cmake '("CMakeLists.txt")
   :compilation-dir "build"
   :configure "cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .."
   :compile "ninja"
   :test "ninja test"))
(use-package projectile-ripgrep)

;; Language Server Protocol (LSP) handler. Enables tons of magic interactions
;; for many programming languages.
(use-package eglot
  :hook ((c-mode-common rust-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs '(rust-mode "rust-analyzer"))
  :custom
  (eglot-autoshutdown t))

;; Code templates, mostly used in conjunction with the LSP but can be useful on
;; its own generating long, boring boilerplate code.
(use-package yasnippet
  :hook
  (prog-mode . yas-minor-mode)
  :bind
  (("C-c y i" . yas-insert-snippet)
   ("C-c y n" . yas-new-snippet)
   ("C-c y v" . yas-visit-snippet-file))
  :config
  (yas-reload-all)
  (setq yas-snippet-dirs '("~/.emacs.d/snippets")))

;;; --- Language specific -----------------------------------------------------
(use-package cc-mode
  :ensure nil
  :hook (c-mode-common . (lambda () (c-set-style "Thoreb")))
  :config
  (c-add-style "Thoreb"
               '("bsd"
                 (c-basic-offset . 4)
                 (c-tab-always-indent . t)
                 (c-offsets-alist
                  (arglist-intro . 8)
                  (case-label    . 4)
                  (innamespace   . 0)
                  (stream-op     . c-lineup-streamop))
                 (indent-tabs-mode . nil))))
(use-package cmake-mode
  :mode (("CMakeLists\\.txt\\'" . cmake-mode)
         ("\\.cmake\\'"         . cmake-mode))
  :custom
  (cmake-tab-width 4))
(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode))
(use-package qml-mode
  :mode "\\.qml\\'")
(use-package rust-mode)
