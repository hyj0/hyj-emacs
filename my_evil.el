(require 'evil)

(add-hook 'evil-mode-hook 
	  (lambda ()
	    (define-key evil-insert-state-map (kbd "ESC") 
	      (lambda () 
		(interactive)
		(progn
		  (message "evil-normal-state")
		  (evil-normal-state)
		  (keyboard-quit)
		  (evil-force-normal-state)
			)))
	    (message "add hook evil")))

(define-key evil-normal-state-map (kbd "f") 'evil-ace-jump-word-mode)

(defun my-forward-sexp (&optional arg interactive)
  (interactive "^p\nd")
  (let ((current-point (point))
	(forward-point (condition-case err (save-excursion
					     (forward-sexp arg interactive)
					     (point))
			 (error
			  ;(message "error:%S" (error-message-string err))
			  -1))))
    ;(message "fp %S %S" current-point forward-point)
    ;(message "sexp:%S" (bounds-of-thing-at-point 'sexp))
    (if (= -1 forward-point)
	(progn
	  (forward-char 1)
	  (backward-sexp))
      (forward-sexp arg interactive))))
;(define-key evil-normal-state-map (kbd "g [") 'forward-sexp)
(define-key evil-normal-state-map (kbd "g [") 'my-forward-sexp)
(global-set-key (kbd "M-[") 'my-forward-sexp)
