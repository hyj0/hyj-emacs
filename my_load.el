(message "my_load ... ")
;(require 'slime)
;(setq inferior-lisp-program "/usr/bin/sbcl")
(add-to-list 'load-path (concat (my-home-dir) "/slime/"))
;(if (eq system-type 'windows-nt)
;      "w:/"
;    (require 'slime-autoloads))
;(setq inferior-lisp-program "/usr/bin/sbcl")
(setq inferior-lisp-program (concat (my-home-dir) "/root_dir/bin/scheme"))
(setq slime-contribs '(slime-scratch slime-editing-commands))

(defun foo ( n)
  (cond ((= n 0) 1)
	((> n 0)
	 (* n (foo (- n 1))))))
(foo 4)

;(add-to-list 'load-path "~/.emacs.d/pomidor/")
;(require 'pomidor)

;(pomidor-mode)

;(require 'alert)
;(alert "aaaa")
;(alert "This is an alert" :title "My Alert")

;(message 'completing-read-function)
(require 'ivy)
(ivy-mode 1)



(ivy--regex-fuzzy "abc")
(setq ivy-re-builders-alist (list  (cons 't 'ivy--regex-fuzzy)))
(debug-on-entry 'ivy--reset-state)
(cancel-debug-on-entry 'ivy--reset-state)

;(setq ivy-re-builders-alist (list  (cons 't 'ivy--regex-plus)))


(setq debug-on-error t)


(global-set-key (kbd "C-x C-x") 'execute-extended-command)
(global-set-key (kbd "C-x x") 'execute-extended-command)



(add-to-list 'load-path (expand-file-name (concat (my-home-dir) "auto-save")))
(require 'auto-save)
(auto-save-enable)

(setq auto-save-silent t)   ; quietly save
(setq auto-save-delete-trailing-whitespace t)  ; automatically delete spaces at the end of the line when saving


(add-to-list 'load-path (expand-file-name (concat (my-home-dir) "aweshell")))
(require 'aweshell)
(add-hook 'eshell-mode-hook (lambda () (company-mode -1)))
