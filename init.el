;;; init.el -*- lexical-binding: t; -*-

;; Check if JSON and built-in native compilation is unavailable.
(unless (functionp 'json-serialize)
  (message "Native JSON is *not* available"))
(unless (and (fboundp 'native-comp-available-p) (native-comp-available-p))
  (message "Native complation is *not* available"))

;;; --- Package handling and settings file locations --------------------------
;; Package configuration as well as use-package
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(require 'use-package-ensure)
(setq use-package-always-ensure t)

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
 ring-bell-function 'ignore    ; Stop annoying sounds
 sentence-end-double-space nil ; Sentences end with a single space where I live
 use-short-answers t           ; y/n instead of yes/no

 ;; Silence startup message, I know about GNU Emacs already
 initial-scratch-message nil
 inhibit-startup-message t

 ;; Pixelwise resizing feels better for me
 window-resize-pixelwise t
 frame-resize-pixelwise t

 ;; Don't create lock files (prefix .#) or backup files (suffix ~)
 create-lockfiles nil
 make-backup-files nil)

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

;;; --- Operating system specific alterations ---------------------------------
;; GNU/Linux
(when (eq system-type 'gnu/linux)
  (set-frame-font "Hack-10.5" nil t))
;; macOS
(when (eq system-type 'darwin)
  (global-set-key [kp-delete] 'delete-char) ; fn-delete == right-delete
  (setq insert-directory-program "/opt/homebrew/bin/gls"
        mac-command-modifier 'meta
        mac-option-modifier 'none))
;; Windows
(when (eq system-type 'windows-nt)
  (set-frame-font "Cascadia Mono-10.5" nil t))

;;; --- User interface things -------------------------------------------------
;; This is me!
(setq-default user-full-name "Jens Bäckman"
              user-mail-address "jens.backman@me.com")

(setq-default column-number-mode t) ; Show line and column in the mode bar

;; Enable Doom modeline and automatically switch between Solarized dark/light
(use-package solarized-theme)
(if (display-graphic-p)
  (progn
    (use-package nerd-icons)
    (use-package doom-modeline
      :hook (after-init . doom-modeline-mode))
    (use-package auto-dark
      :init
      (setq auto-dark-dark-theme 'solarized-dark)
      (setq auto-dark-light-theme 'solarized-light)
      (auto-dark-mode t))))

;; In order to help me explore and verify key bindings, I'm using which-key.
;; As soon as I press a key binding like C-c and wait for a while, a panel
;; will appear and display all bindings under that prefix and which command
;; they run.
(which-key-mode)

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
  (add-to-list 'projectile-globally-ignored-directories "^elpa$")
  (add-to-list 'projectile-globally-ignored-directories "^node_modules$")
  (add-to-list 'projectile-globally-ignored-directories "^target$")
  ;; Add custom commands for CMake projects
  (projectile-register-project-type
   'cmake '("CMakeLists.txt")
   :project-file "CMakeLists.txt"
   :compilation-dir "build"
   :configure "cmake -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .."
   :compile "ninja"
   :test "ninja test")
  (projectile-register-project-type
   'dotnet-sln '(".vssln")
   :project-file "?*.sln"
   :compile "dotnet build"'
   :run "dotnet run"
   :test "dotnet test"))
(use-package projectile-ripgrep)

;;; --- Programming life enhancers --------------------------------------------
;; Tree-sitter is an incremental parsing system for programming tools. Enables
;; wider interactions with source code. Language specific grammars must be
;; installed for this to work.
(setq major-mode-remap-alist
      '((bash-mode . bash-ts-mode)
        (js-mode . js-ts-mode)
        (python-mode . python-ts-mode)
        (rust-mode . rust-ts-mode)
        (sh-mode . bash-ts-mode)))
(dolist (mode '(("\\.ts\\'" . typescript-ts-mode)
                ("\\.tsx\\'" . tsx-ts-mode)
                ("\\.ya?ml\\'" . yaml-ts-mode)))
  (add-to-list 'auto-mode-alist mode))
(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
        (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
        (python "https://github.com/tree-sitter/tree-sitter-python")
        (rust "https://github.com/tree-sitter/tree-sitter-rust")
        (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
        (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml/" "master" "src")))
(defun czw/install-treesitter-grammars ()
  "Install all specified Tree-sitter language grammars"
  (interactive)
  (dolist (lang treesit-language-source-alist)
    (condition-case err
        (treesit-install-language-grammar (car lang))
      (error (message "Failed to install %s: %s" (car lang) err)))))

;; Language Server Protocol (LSP) handler. Enables tons of magic interactions
;; for many programming languages.
(use-package eglot
  :hook (prog-mode . czw/eglot-ensure)
  :bind
  (("C-c e a" . eglot-code-actions)
   ("C-c e f" . eglot-format)
   ("C-c e r" . eglot-rename))
  :custom
  (eglot-autoshutdown t))
(defun czw/eglot-ensure ()
  "Start Eglot session for current buffer unless it's in a blacklisted mode."
  (unless (string= "emacs-lisp-mode" major-mode)
    (eglot-ensure)))

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
(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode))
(use-package rust-mode)
