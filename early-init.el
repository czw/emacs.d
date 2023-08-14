;;; early-init.el -*- lexical-binding: t; -*-
;;
;; This file was introduced in Emacs 27. It is loaded very early on in the init
;; process, giving us a change to increase garbage collection threshold and
;; other handy things.

;; Disable garbage collection when we start Emacs, re-enable after init
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          #'(lambda () (setq gc-cons-threshold (* 32 1024 1024))))

;; Native compilation
(when (featurep 'native-compile)
  ;; Move the native compilation directory to a less obnoxious place
  (setcar native-comp-eln-load-path
          (concat user-emacs-directory "var/eln-cache/"))
  ;; Be quiet when compiling, I don't develop Emacs packages
  (setq native-comp-async-report-warnings-errors nil)
  ;; Interpret Lisp, compile in the background, use compiled code when done
  (setq native-comp-deferred-compilation t))

;; Increase the amount of data which Emacs reads from the processes, increasing
;; performance with LSP. The default is 4KB while LSP responses can be huge.
(setq read-process-output-max (* 1024 1024)) ; 1MB

;; Make minor UI adjustments really early on
(push '(tool-bar-lines . 0) default-frame-alist)
(when (featurep 'ns)
  (push '(ns-transparent-titlebar . t) default-frame-alist))

;; Resizing the Emacs frame can be a terribly expensive part of changing the
;; font. By inhibiting this, we easily halve startup times with fonts that are
;; larger than the system default.
(setq frame-inhibit-implied-resize t)

;; Ignore X resources; its settings would be redundant with the other settings
;; in this file and can conflict with later config (particularly where the
;; cursor color is concerned).
(advice-add #'x-apply-session-resources :override #'ignore)

;; Show how quickly Emacs initialized
(add-hook
 'emacs-startup-hook
 (lambda ()
   (message "Emacs ready in %s with %d garbage collections."
            (format "%.2f seconds"
                    (float-time
                     (time-subtract after-init-time before-init-time)))
            gcs-done)))
