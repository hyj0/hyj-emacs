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
  (when nil
    (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.2")))


(toggle-debug-on-error)


(add-hook 'after-init-hook 'global-company-mode)

;(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path (my-home-dir))
;
(autoload 'paredit-mode "paredit"
  "Minor mode for pseudo-structurally editing Lisp code."
 t)


(add-hook 'after-init-hook
	  (lambda ()
	    (require 'evil)
	    (evil-mode)
	    ;(evil-define-key 'visual global-map "." 'my-translate-selected-text)
	    (evil-global-set-key 'visual "." 'my-translate-selected-text)
	    (defun my-translate-selected-text ()
	      "显示选中的文本"
	      (interactive)
	      (if (use-region-p)  ;; 检查是否有选中区域
		  (let ((selected-text (buffer-substring (region-beginning) (region-end))))  ;; 获取选中的文本
					;(message "选中的文本是: %s" selected-text)
		    (eaf-translate-text selected-text))  ;; 显示选中的文本
		(message "没有选中文本！")))
	    ))

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
			       (load (concat prefix "my_database.el"))
			       (load (concat prefix "my_eaf_term.el"))
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
(add-hook 'python-mode-hook (lambda ()
			      (elpy-enable)
			      (paredit-mode 1)
			      (require 'rainbow-mode)
			      (rainbow-mode 1)))


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

(defalias 'yes-or-no-p 'y-or-n-p)

(require 'mini-frame)
(custom-set-variables
 '(mini-frame-show-parameters
   '((top . 10000)
     (width . 0.4)
     (left . 0.0))))
;(mini-frame-mode 1)

(with-eval-after-load "~/.emacs.d/init.el"
  (add-to-list 'load-path (concat (my-home-dir) "sort-tab"))
  (require 'sort-tab)
  (setq sort-tab-name-max-length 25)
  (setq sort-tab-show-index-number t)
  (sort-tab-mode 1)

  (global-set-key (kbd "M-1") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-2") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-3") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-4") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-5") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-6") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-7") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-8") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-9") 'sort-tab-select-visible-tab)
  (global-set-key (kbd "M-0") 'sort-tab-select-visible-tab)
  ;(global-set-key (kbd "s-Q") 'sort-tab-close-all-tabs)
  (global-set-key (kbd "M-q") 'sort-tab-close-mode-tabs)
  ;(global-set-key (kbd "C-;") 'sort-tab-close-current-tab)
  )

(require 'popper)
(popper-mode +1)

(require 'popper-echo)
(popper-echo-mode +1)


(setq popper-reference-buffers
      '("\\*Messages\\*"
        "Output\\*$"
        "\\*Async Shell Command\\*"
        help-mode
        compilation-mode))


(defvar *my-win-conf* nil)
(defvar *cur-win-conf* nil)
(defvar *old-win-conf* nil)
(defvar *old-win-conf2* nil)

(defun my-window-record ()
  (interactive)
  (setq *my-win-conf* (current-window-configuration)))

(defun my-window-play ()
  (interactive)
  (when *my-win-conf*
    (set-window-configuration *my-win-conf*)))

(defun my-window-back ()
  (interactive)
  (set-window-configuration *old-win-conf*)
  )

(defun my-window-back2 ()
  (interactive)
  (set-window-configuration *old-win-conf2*)
  )


(defun my-window-config-change ()
  (setq *old-win-conf2* *old-win-conf*)
  (setq *old-win-conf* *cur-win-conf*)
  (setq *cur-win-conf* (current-window-configuration))
  )

(setq  window-configuration-change-hook (append window-configuration-change-hook '(my-window-config-change)))



(message "init.el end")
