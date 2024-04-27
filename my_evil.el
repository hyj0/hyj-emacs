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
