;;;;;;;;;;;;
;; Scheme
;;;;;;;;;;;;

(require 'cmuscheme)
(message "my scheme")

;; push scheme interpreter path to exec-path
(push "/data/projector/root_dir/bin" exec-path)

;; scheme interpreter name
(setq scheme-program-name "scheme")

;; bypass the interactive question and start the default interpreter
(defun scheme-proc ()
  "Return the current Scheme process, starting one if necessary."
  (unless (and scheme-buffer
               (get-buffer scheme-buffer)
               (comint-check-proc scheme-buffer))
    (save-window-excursion
      (run-scheme scheme-program-name)))
  (or (scheme-get-process)
      (error "No current process. See variable `scheme-buffer'")))

(defun switch-other-window-to-buffer (name)
    (other-window 1)
    (switch-to-buffer name)
    (other-window 1))

(defun scheme-split-window ()
  (cond
   ((= 1 (count-windows))
    (split-window-vertically (floor (* 0.68 (window-height))))
    ;; (split-window-horizontally (floor (* 0.5 (window-width))))
    (switch-other-window-to-buffer "*scheme*"))
   ((not (member "*scheme*"
               (mapcar (lambda (w) (buffer-name (window-buffer w)))
                       (window-list))))
    (switch-other-window-to-buffer "*scheme*"))))

(defun scheme-send-last-sexp-split-window ()
  (interactive)
  (scheme-split-window)
  (scheme-send-last-sexp))

(defun scheme-send-definition-split-window ()
  (interactive)
  (scheme-split-window)
  (scheme-proc)
  (scheme-send-region (point-min) (point-max)))



(defun myscheme-send-last-sexp()
  (let ((start (save-excursion (backward-sexp) (+ (point) 0)))
	(end (+ (point) 0))
	(cur (current-buffer)))
    (message "point %d %d" start end)
    (let ((s (with-current-buffer (current-buffer)
	       (buffer-substring start end)))
	  (name "*scheme*"))
      (message "s=%s" s)
      (set-buffer name)
      (with-current-buffer name
	(message "cur %s" name)
	;(goto-char (- (point-max) 0))
	;(end-of-buffer)
	(insert s)
	;(end-of-buffer)
	(goto-char (point-max))
	(comint-send-input))
      (set-buffer cur)
      (message "end"))))

(defun myscheme-send-last-sexp2 ()
  (let ((start (save-excursion (backward-sexp) (+ (point) 0)))
	(end (+ (point) 0))
	(cur (current-buffer)))
    (comint-send-region (scheme-proc) start end)
    (comint-send-string (scheme-proc) "\n")))

(defun scheme-send-last-sexp-split-window2 ()
  "Send the last S-expression to Scheme process and evaluate it."
  (interactive)
  (let ((sexp (save-excursion
                (goto-char (preceding-sexp))
                (thing-at-point 'sexp))))
    (save-window-excursion
      (switch-to-buffer-other-window "*scheme*")
      (goto-char (point-max))
      (insert sexp)
      (comint-send-input))))

(defun scheme-send-last-sexp-split-window1 ()
  (interactive)
  (scheme-split-window)
  (scheme-proc)
  (if (and (bound-and-true-p evil-mode) (evil-normal-state-p))
      (progn
	(message "evil-normal-state")
	(evil-insert-state)
	(goto-char (+ 1 (point)))
	(scheme-send-last-sexp)
	(evil-normal-state))
    (scheme-send-last-sexp)))

;(funcall  (lambda () (scheme-send-last-sexp-split-window1)))

(add-hook 'scheme-mode-hook
  (lambda ()
    (paredit-mode 1)
    (define-key scheme-mode-map (kbd "<f5>") 'scheme-send-last-sexp-split-window1)
    (define-key scheme-mode-map (kbd "C-x C-e") 'scheme-send-last-sexp-split-window1)
    (define-key scheme-mode-map (kbd "<f6>") 'scheme-send-definition-split-window)))


(add-to-list 'auto-mode-alist
	     '("\\.\\(sls\\|sps\\)\\'" . scheme-mode))
