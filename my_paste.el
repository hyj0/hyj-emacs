(defvar loop-paste-file (concat (my-home-dir) "loop-paste-file.txt"))
(defvar loop-paste-timer nil)

(defun paste--to-file ()
  (interactive)
  (let ((content (string-trim-right (current-kill 0))))
    ;(message "start paste")
    (with-current-buffer (find-file-noselect loop-paste-file)
      ;(message "paste")
      (let ((buffer (if (> (point-min) (- (point-max) 1))
			""
		      (string-trim-right (buffer-substring (point-min) (-  (point-max) 1))))))
	(if (string= content buffer)
	    (progn
	      ;(message "%s == %s" content buffer)
	      nil)
	  (progn
	    ;(message "%s != %s %d %d " content buffer (length content) (length buffer))
	    (erase-buffer)
	    (goto-char (point-max))
	    (insert content)
	    (let ((save-silently t))
	      (save-buffer))
	    't)))))) 

(defun paste-to-file ()
  (condition-case error 
      (paste--to-file)
    (error
     (message "at error")
     (kill-buffer "loop-paste-file.txt")
     (find-file-noselect loop-paste-file))))

(defun paste-start ()
  (if loop-paste-timer
      (cancel-timer loop-paste-timer))
  (find-file-noselect loop-paste-file)
  (kill-new "abc")
  (setq loop-paste-timer  (run-at-time "1 sec" 1 'paste-to-file)))

(defun paste-stop ()
  (cancel-timer loop-paste-timer))

;(when (os-is-linux)
;  (paste-start))

;(paste-to-file) 
(if 't
    nil
  (progn
    (paste-to-file)
    (paste-stop)
    ))

