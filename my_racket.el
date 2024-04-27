;(require 'racket)


(defun my-racket-send-last-sexp-hook (org-fun &optional prefix)
  (if (evil-normal-state-p)
      (progn
	(evil-insert-state)
	(goto-char (+ 1 (point)))
	(let ((ret (apply org-fun prefix)))
	  (evil-normal-state)
	  ret))
    (apply org-fun prefix)))

(advice-add 'racket-send-last-sexp :around 'my-racket-send-last-sexp-hook)

;(advice-remove 'racket-send-last-sexp :around)

