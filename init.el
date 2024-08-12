(when nil
  (progn
    (package-refresh-contents)
    (package-install 'evil)
    (package-install 'ivy)
    (package-install 'company)
    ;down load https://paredit.org/releases/26/paredit.el to hyj-emacs
    (package-install 'rainbow-mode)
    ))
(defun os-is-linux ()
  (if (eq system-type 'gnu/linux)
      t
    nil))
(defun os-is-windows ()
  (if (eq system-type 'windows-nt)
      t
    nil))

(defun my-home-dir ()
  (if (os-is-windows)
      "w:/.emacs.d/hyj-emacs/"
    "~/.emacs.d/hyj-emacs/"))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(if (os-is-windows)
    (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.1")
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.2"))


(toggle-debug-on-error)


(add-hook 'after-init-hook 'global-company-mode)

;(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path (my-home-dir))
;
(autoload 'paredit-mode "paredit"
  "Minor mode for pseudo-structurally editing Lisp code."
 t)


(add-hook 'after-init-hook 'evil-mode)
(add-hook 'after-init-hook (lambda ()
			     (let ((prefix (my-home-dir)))
			       (global-auto-revert-mode)
			       (load (concat prefix "my_scheme.el"))
			       (load (concat prefix "my_evil.el"))
			       ;(load (concat prefix "auto-save.el"))
			       (load (concat prefix "my_load.el"))
			       (load (concat prefix "my_paste.el"))
			       (load (concat prefix "my_racket.el"))
			       (load (concat prefix "my_complete.el"))
			       (load (concat prefix "my_pomidor.el"))
			       (load (concat prefix "my_kubectl.el"))
			       (load (concat prefix "my_eaf.el"))
			       )))
;(requirel 'evil)
;(evil-mode 1)
;(show-paren-mode 1)
;(paredit-mode 1)

(defun enable-lisp-mode()
  (paredit-mode 1)
  (require 'rainbow-mode)
  (rainbow-mode 1)
  (show-paren-mode 1))

(add-hook 'emacs-lisp-mode-hook #'enable-lisp-mode)
(add-hook 'scheme-mode-hook #'enable-lisp-mode)
(add-hook 'racket-mode-hook #'enable-lisp-mode)


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(dichromacy))
 '(package-selected-packages
   '(eglot org vterm python json-mode capf-autosuggest ivy dash racket-mode paredit rainbow-mode macrostep evil company auto-complete)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(set-background-color "#C6EECB")
(put 'list-timers 'disabled nil)
(message "init.el end")
