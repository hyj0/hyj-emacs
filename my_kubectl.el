
(defvar *kube-config* "")

(defun get-pod-cmd (&optional filter-name)
  (get-kube-cmd "get po" filter-name))
(defun get-deployment-cmd (&optional filter-name)
  (get-kube-cmd "get deployment" filter-name "| awk '{print $1}'"))
(defun get-kube-cmd (action &optional filter-name tail-cmd)
  (let ((ret (format "kubectl %s %s %s %s"
		      *kube-config*
		      action
		      (if (and  filter-name (>  (length filter-name) 0))
			  (format "|grep %s" filter-name)
			"")
		      (if (and tail-cmd (> (length tail-cmd) 0))
			  tail-cmd
			"")
		      )))
    (message "cmd=%s" ret)
    ret))
(defun get-pod (&optional filter-name)
  (let ((cmd (format "kubectl %s  get po  %s | awk '{print $1}'"
		     *kube-config*
		     (if (and  filter-name (>  (length filter-name) 0))
			 (format "|grep %s" filter-name)
		       "")
		     )))
    (message "cmd=%s" cmd)
    (string-replace "\n" " " (string-trim  (shell-command-to-string cmd))))
  )
(defun get-deployment (&optional filter-name)
  (let ((cmd (get-deployment-cmd filter-name)))
    (message "cmd=%s" cmd)
    (string-replace "\n" " " (string-trim (shell-command-to-string cmd)))))

(defun follow-log (filter-name)
  (interactive "sPod-name:")
  (let* ((pod-name (car (split-string (get-pod filter-name) " ")))
	(cmd (format "kubectl %s --tail=100 logs -f %s"
		     *kube-config*
		     pod-name
		     )))
    (message "cmd=%s" cmd)
    (if (<=  (length pod-name) 0)
	nil
      (progn
	(start-process-shell-command cmd cmd cmd)
	(switch-to-buffer cmd)))
    ))
(defun command-with-shell (cmd &optional buffer-name)
  (if buffer-name
      nil
    (setq buffer-name cmd))
  (shell buffer-name)
  (sleep-for 1)
  (with-current-buffer buffer-name
    (goto-char (point-max))
    (insert cmd)
    (comint-send-input))
  (switch-to-buffer buffer-name))
(defun pod-shell (pod)
  (let ((pod-name (car (split-string (get-pod pod)))))
    (when (> (length pod-name) 0)
      (command-with-shell   (get-kube-cmd (format  "exec -it %s -- sh " pod-name))))))
(defun restart-deployment (filter-name)
  (let ((cmd (concat  (get-kube-cmd "rollout restart deployment") (get-deployment filter-name))))
    (message "cmd=%s" cmd)
    (shell-command cmd)
    )
  )

(defun kube-apply (file)
  (interactive "fK8S file:")
  (let ((cmd (concat  (get-kube-cmd "apply  --validate=false -f ") file)))
    (message "cmd=%s" cmd)
    (shell-command cmd))
  )
(defun kube-delete (file)
  (interactive "fK8S file:")
  (let ((cmd (concat  (get-kube-cmd "delete -f ") file)))
    (message "cmd=%s" cmd)
    (shell-command cmd))
  )
(defun kube-scale (name count)
  (let ((dep (get-deployment name)))
    (when (>  (length dep) 0)
      (let ((cmd (concat (get-kube-cmd (format  "scale --replicas=%d deployment/%s" count dep)) ""))
	    )
	(message "cmd=%s" cmd)
	(shell-command cmd)))
    ))


(defun get-node-ip ()
  (let ((ip (string-trim  (shell-command-to-string  (get-kube-cmd "get nodes -o jsonpath='{.items[*].status.addresses[?(@.type==\"InternalIP\")].address}{\"\\n\"}' | awk '{print $1}'")))))
    ip))
(defun get-service-endpoint (filter-name)
  (let ((cmd (get-kube-cmd "get svc -o jsonpath='{range .items[*]}{.metadata.name} {.spec.ports[0].nodePort}{\"\\n\"}{end}'" filter-name))
	(ret-list '())
	(node-ip (get-node-ip)))
    (message "node-ip=%s" node-ip)
    (message "cmd=%s" cmd)
    (let ((svc-str (shell-command-to-string cmd)))
      (dolist (line (split-string svc-str "\n" 't))
	(let ((sp (split-string line " " 't)))
	  (when sp
	    ;(print sp)
	    (let* ((port (nth 1 sp))
		   (name (nth 0 sp))
		   (end-point (format "http://%s:%s" node-ip port)))
	      (if ret-list
		  ;(setq ret-list (cons (cons  end-point name) ret-list))
		  (add-to-list 'ret-list (list end-point name port))
		(setq ret-list (list (list end-point name port )))))
	    ))))
    ret-list)
  )

(defun kube-get-doc (name)
  (let ((lst (split-string  (shell-command-to-string  (get-kube-cmd "get svc | awk '{print $1}'" name))))
	(res '()))
    (dolist (one lst)
      (when (>  (length one) 0)
	(if res
	    (setq res (add-to-list 'res (list one (concat  (car  (car
								  (get-service-endpoint one))) "/doc.html"))))
	  (setq res (list (list one (concat  (car  (car
						    (get-service-endpoint one))) "/doc.html")))))
	)
      )
    (message "%S" res)
    (dolist (one res)
      (message "%S" one)))
  )
