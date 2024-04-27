


(defvar *my-pomidor-timer* nil)

(defvar *my-pomidor-work-dur* '(("09:00:00" "11:40:00") ("13:30:00" "18:30:00")))

;status: 1--work,2--rest
(defun my-pomidor-timer-callback (status name start-time dur-sec)
  ;check status
  (cond ((not status) (message "err: none work or rest"))
	((= 1 status) (progn
			(let ((dur (* 60 5))
			      (start-sec (float-time (current-time))))
			  (setq *my-pomidor-timer* (run-at-time dur nil 'my-pomidor-timer-callback 2 name (current-time) dur))
			  (write-work-log (list 'my-pomidor-deal-work-log status name start-time dur-sec (format-time-string "%Y-%m-%d %H:%M:%S" start-time)))
			  (while (and nil (< (float-time (current-time)) (+ start-sec dur -5)))
			    (sleep-for 1)
			    (message-box (format "======================%s==================== %s \r\n====================================================================" name "工作完成，请休息！")))
			  (message-box (format "======================%s==================== %s \r\n====================================================================" name (concat  "工作完成，请休息！" (get-eated-yao-message))))
			  (sleep-for 2)
			  (message-box (format "======================%s==================== %s \r\n====================================================================" name (concat  "工作完成，请休息！" (get-eated-yao-message))))
			  )))
	((= 2 status) (progn
			(setq *my-pomidor-timer* nil)
			(message-box (format "=====================%s================= %s ===============================================================================" name (concat  "休息完成，请工作！" (get-eated-yao-message))))
			(sleep-for 1)
			(message-box (format "=====================%s================= %s ===============================================================================" name (concat  "休息完成，请工作！" (get-eated-yao-message))))
			(let ((contine (x-popup-dialog (selected-frame)
						       (list (concat  "休息完成，是否继续该工作？" name)
							   ;(format "%s %s" name "休息完成，是否继续该工作？")
							  '("Yes" . t)
							  '("No" . nil))
							t)))
			  (when contine
			    (my-pomidor-start name)))))
	)
  ;work end, pod message, log work
  ;rest end, pod message, log rest
  )


(defun my-pomidor-start (name &optional rest)
  (interactive)
  (if rest
      (my-pomidor-rest name)
;check status
    (if (not *my-pomidor-timer*)
	(progn
					;start timer
	  (let ((dur (check-dur (* 60 25))))
	    (if dur
		(progn
		  (setq *my-pomidor-timer* (run-at-time dur nil 'my-pomidor-timer-callback 1 name (current-time) dur))
		  (my-pomidor-status))
	      (progn
		(message "not in work time!! wait ")
		))
	    )
	  )
      (my-pomidor-status)))
  )

(defun my-pomidor-rest (name)
  (interactive)
  ;check status
  (if (not *my-pomidor-timer*)
      (progn
  ;start timer
	(let ((dur (check-dur (* 60 5))))
	  (if dur
	      (progn
		(setq *my-pomidor-timer* (run-at-time dur nil 'my-pomidor-timer-callback 2 name (current-time) dur))
		(my-pomidor-status))
	    (progn
	      (message "not in work time!! wait ")
	      ))
	  )
	)
    (my-pomidor-status))
  )

(defun sec-to-min (sec)
  (if (> sec 60)
      (let ((min (/ sec 60))
	    (secs (% sec 60)))
	(format "%dm%dsec" min secs))
    (format "0m%dsec" sec)))

(defun my-pomidor-status ()
  (interactive)
  (if *my-pomidor-timer*
      (let* ((args (timer--args *my-pomidor-timer*))
	     (status (nth 0 args))
	     (name (nth 1 args))
	     (start-time (nth 2 args))
	     (dur-sec (nth 3 args))
	     (res-sec (floor (- dur-sec (- (float-time (current-time)) (float-time start-time)))))
	     (time-msg (sec-to-min res-sec)))
	(cond ((= 1 status) (message (prin1-to-string (list "working" name time-msg (get-eated-yao-message)))
				     ))
	      ((= 2 status) (message (prin1-to-string (list "resting" name time-msg (get-eated-yao-message)))))
	      ((t (message "err status")))))

    (message (concat  "none work or rest" (get-eated-yao-message))))
  )

(defun my-pomidor-cancel ()
  (interactive)
  (if *my-pomidor-timer*
      (progn
	(write-work-log (get-work-log-from-timer *my-pomidor-timer*))
	(cancel-timer *my-pomidor-timer*)
	(setq *my-pomidor-timer* nil))
    (message (concat  "none work or rest" (get-eated-yao-message))))
  )


(defun check-dur (dur)
  (let* ((work-dur-timestamp
	 (mapcar (lambda (c)
		   (let ((start (car c))
			 (end (car (cdr c))))
		     (list
		      (float-time (date-to-time (format "%s %s" (format-time-string "%Y-%m-%d" (current-time)) start)))
		      (float-time (date-to-time (format "%s %s" (format-time-string "%Y-%m-%d" (current-time)) end))))
		     ))
		 *my-pomidor-work-dur*))
	(cur-timestamp (float-time (current-time)))
	(work-end-timestamp (+ cur-timestamp dur)))
    (cl-reduce (lambda (x y)
		 (cond ((and x y) (min x y))
		       (x x)
		       (y y)
		       (t nil)))
	       (mapcar (lambda (c)
			 (let ((start (car c))
			       (end (car (cdr c))))
			   (cond ((<= end cur-timestamp) nil)
				 ((<= work-end-timestamp start) nil)
				 ((and (>=  cur-timestamp start) (<= cur-timestamp end))
				  (progn
				    (if (> work-end-timestamp end)
					(progn
					  (message "dur from %d to %d" dur (- end cur-timestamp))
					  (- end cur-timestamp))
				      dur)))
				 (t dur))
			   ))
		       work-dur-timestamp))))

(defun get-work-log-from-timer (timer)
  (if *my-pomidor-timer*
      (let* ((args (timer--args *my-pomidor-timer*))
	     (status (nth 0 args))
	     (name (nth 1 args))
	     (start-time (nth 2 args))
	     (dur-sec (nth 3 args))
	     (res-sec (floor (- dur-sec (- (float-time (current-time)) (float-time start-time)))))
	     (time-msg (sec-to-min res-sec)))
	(cond ((= 1 status)
	       (progn
		 (message (prin1-to-string (list "working" name time-msg)))
		 (list 'my-pomidor-deal-work-log status name start-time (floor (- (float-time (current-time)) (float-time start-time))) (format-time-string "%Y-%m-%d %H:%M:%S" start-time))
		 ))
	      (t nil)))

    (message "none work or rest")))

(defun write-work-log (log)
  (when log
    (append-to-file (format "%S" log) nil (concat (my-home-dir) "work-log.el"))
    (append-to-file "\n" nil (concat (my-home-dir) "work-log.el")))
  )







(defun eated-yao-time-file ()
  (concat (my-home-dir) "eated-yao-time.txt"))

(defun eated-yao-p (time-stamp)
  (if (file-exists-p (eated-yao-time-file))
      (let ((text (read-file-content (eated-yao-time-file)))
	    (input-time (*  (/  (truncate  time-stamp) (* 60 60 24) ) (* 60 60 24))))
	(message text)
	(let ((eated-time (string-to-number text 10)))
	  (if (= eated-time input-time)
	      t
	    nil)))
    nil))
(defun eated-yao-p1 ()
  (eated-yao-p (float-time (current-time))))

(defun mark-eat-yao (time-stamp)
  (let ((text (format "%S"  (*  (/  (truncate  time-stamp) (* 60 60 24) ) (* 60 60 24)))))
    (write-to-file (eated-yao-time-file) text)))
(defun mark-eat-yao1 ()
  (mark-eat-yao (float-time (current-time))))


(defun read-file-content (file-path)
  "读取文件内容并返回字符串"
  (with-temp-buffer
    (insert-file-contents file-path)
    (buffer-string)))

(defun write-to-file (file-path content)
  "将内容覆盖写入文件"
  (with-temp-buffer
    (insert content)
    (write-region (point-min) (point-max) file-path nil 'no-message)))

(defun get-eat-yao-msg2 ()
  (let ((day (format-time-string "%Y-%m-%d" (float-time (current-time)))))
    (if (string< day "2024-03-24")
	"-->吃药1粒"
      (let  ((day-num  (string-to-number  (car  (last  (split-string day "-"))))))
	(if (= 0 (mod day-num 2))
	    "-->吃药一粒"
	  "-->吃药1粒")))))

(defun get-eated-yao-message0 ()
  (if (eated-yao-p1)
      "--"
    (get-eat-yao-msg2)))

;todo: check firefox and monitor process
(defun check-firefox-monitor ()
  (if (os-is-windows)
      (let ((mod-time (float-time  (file-attribute-modification-time
			   (file-attributes "c:/Users/13581/CLionProjects/test/expires_timestamp.txt")))))
	(if (> (- (float-time (current-time)) mod-time) 3600)
	    "firefox或者monitor未启动"
	  "-"))
    "-"))
(defun get-restart-mp-weixin-message ()
  (if (os-is-windows)
      (let ((expire_time (string-to-number (read-file-content "c:/Users/13581/CLionProjects/test/expires_timestamp.txt")))
	    (curr_time (floor (float-time (current-time)))))
	(if (> curr_time expire_time)
	    "公众号已过期，请登录"
	  "-"))
    "-"))

(defun get-eated-yao-message ()
  (concat (get-eated-yao-message0)
	  ;"-" (get-restart-mp-weixin-message) (check-firefox-monitor)
	  ))
