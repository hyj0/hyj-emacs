
(defvar *kube-config* "")

(defun get-pod-cmd (&optional filter-name)
  (get-kube-cmd "get po" filter-name))
(defun get-deployment-cmd (&optional filter-name)
  (get-kube-cmd "get deployment" filter-name "| awk '{print $1}'"))
(defun get-statefulset-cmd (&optional filter-name)
  (get-kube-cmd "get statefulset" filter-name "| awk '{print $1}'"))
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
(defun select-pod (&optional filter-name)
  (let ((cmd (format "kubectl %s  get po -o wide %s"
		     *kube-config*
		     (if (and  filter-name (>  (length filter-name) 0))
			 (format "|grep %s" filter-name)
		       "")
		     )))
    (message "cmd=%s" cmd)
    (car (string-split  (my-ivy-read "pod:" (string-split (string-trim  (shell-command-to-string cmd)) "\n")) " ")))
  )

(defun kube-select-service ()
  (car (string-split (completing-read "service:" (string-split  (shell-command-to-string (get-kube-cmd "get svc")) "\n")))))

(defun get-deployment (&optional filter-name)
  (let ((cmd (get-deployment-cmd filter-name)))
    (message "cmd=%s" cmd)
    (string-replace "\n" " " (string-trim (shell-command-to-string cmd)))))
(defun select-deployment (&optional filter-name)
  (completing-read "deployment:" (string-split (get-deployment filter-name) " ")))

(defun  get-statefulset (&optional filter-name)
  (let ((cmd (get-statefulset-cmd filter-name)))
    (message "cmd=%s" cmd)
    (string-replace "\n" " " (string-trim (shell-command-to-string cmd)))))

(defun follow-log (filter-name &optional count)
  (interactive "sPod-name:")
  (let* ((pod-name (select-pod filter-name))
	(cmd (format "kubectl %s --tail=%d logs %s -f --container=%s "
		     *kube-config*
		     (if count
			 count
		       100)
		     pod-name
		     (get-pod-container pod-name)
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
  (when (get-buffer buffer-name)
    (setq buffer-name (concat buffer-name "-" (format "%d" (float-time (current-time))))))
  (shell buffer-name)
  (sleep-for 1)
  (with-current-buffer buffer-name
    (goto-char (point-max))
    (insert cmd)
    (comint-send-input))
  (switch-to-buffer buffer-name))
(defun command-with-shell-eaf (command &optional buffer-name)
  (let* ((dir (eaf--non-remote-default-directory))
	(args (make-hash-table :test 'equal))
         (expand-dir (expand-file-name dir)))
    (puthash "command" command args)
    (puthash
     "directory"
     (if (eaf--called-from-wsl-on-windows-p)
         (eaf--translate-wsl-url-to-windows expand-dir)
       expand-dir)
     args)
    (eaf-open command "pyqterminal" (json-encode-hash-table args) t)))

(defun ssh-eaf (host user passwd &optional proxy port ext-opt)
  (command-with-shell-eaf (format  "sshpass -p %s ssh  %s@%s  %s  %s -o StrictHostKeyChecking=no  -o ServerAliveInterval=60 -o ServerAliveCountMax=3  %s "
				   passwd
				   user
				   host
				   (if port
				       (format "-p %d" port)
				     "")
				   (if proxy
				       "-o ProxyCommand='nc -X 5 -x 127.0.0.1:1080 %h %p'"
				     "")
				   (if ext-opt
				       ext-opt
				     ""))))

(defun ssh-eaf-authinfo ()
  (interactive)
  (let ((sp  (mapcar (lambda (one) (list (format "/%s:%s@%s:/" (plist-get one :port) (plist-get one :user) (plist-get one :host)) one))  (auth-source-search :max 100 ))))
    (let ((info (car (my-assoc (completing-read "authinfo:" sp) sp))))
      (ssh-eaf (plist-get info :host) (plist-get info :user) (auth-info-password info) t))))
(defun get-pod-container (pod-name)
  (let ((containers (string-split (shell-command-to-string  (get-kube-cmd (concat "get pod " pod-name " -o jsonpath='{.spec.containers[*].name}'"))) " ")))
    (if (> (length containers) 1)
	(completing-read "container:" containers)
      (car containers)))
  )
(defun pod-shell (pod)
  (let ((pod-name (select-pod pod))
	(container ""))
    (when (> (length pod-name) 0)
      (command-with-shell-eaf   (get-kube-cmd (format  "exec -it  %s --container=%s -- sh " pod-name (get-pod-container pod-name)))))))
(defun restart-deployment (filter-name)
  (let* ((deploy-name (get-deployment filter-name))
	(cmd (concat  (get-kube-cmd "rollout restart deployment") deploy-name)))
    (message "cmd=%s" cmd)
    (when (> (length deploy-name) 0)
      (shell-command cmd))
    )
  )
(defun restart-statefulset (filter-name)
  (let* ((deploy-name (get-statefulset filter-name))
	(cmd (concat  (get-kube-cmd "rollout restart statefulset") deploy-name)))
    (message "cmd=%s" cmd)
    (when (> (length deploy-name) 0)
      (shell-command cmd))
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

(defun get-node-ips ()
  (let ((ip (string-trim  (shell-command-to-string  (get-kube-cmd "get nodes -o jsonpath='{.items[*].status.addresses[?(@.type==\"InternalIP\")].address}{\"\\n\"}'")))))
    ip))


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
								  (get-service-endpoint one)))
							   "/doc.html"))))
	  (setq res (list (list one (concat  (car  (car
						    (get-service-endpoint one)))
					     "/doc.html")))))
	)
      )
    (message "%S" res)
    (dolist (one res)
      (message "%S" one))
    res)
  )


(defun kube-get-pod-status (name)
  (shell-command (get-kube-cmd (concat  "describe pod " (select-pod name))))
  (when (not (get-buffer-window "*Shell Command Output*" 'visible))
    (switch-to-buffer "*Shell Command Output*")))

(defun switch-to-show (&optional buffer-name)
  (let ((name (if buffer-name
		  buffer-name
		"*Shell Command Output*")))
    (when (not (get-buffer-window name 'visible))
      (switch-to-buffer name))))

(defun kube-open-doc (name)
  (setq name
	(completing-read "service:"
			 (string-split
			  (shell-command-to-string (get-kube-cmd "get svc | awk '{print $1}'" name )))))
  (let ((lst (kube-get-doc name)))
    (eaf-open-browser (nth 1 (nth 0 lst)))))

(defun my-rsync (local-dir host-and-path passwd)
  (let ((cmd (format "rsync -rv -e 'sshpass -p %s ssh -o StrictHostKeyChecking=no -o ProxyCommand=\"nc -X 5 -x 127.0.0.1:1080 %%h %%p\"' %s %s"
		     passwd
		     (if (file-directory-p local-dir)
			 (concat local-dir "/*")
		       local-dir)
		     host-and-path)))
    (message "cmd=%s" cmd)
    (shell-command cmd)
    )
  )
(defun my-rsync-to-local (host-and-path local-dir passwd)
  (let ((cmd (format "rsync -rv -e 'sshpass -p %s ssh -o StrictHostKeyChecking=no -o ProxyCommand=\"nc -X 5 -x 127.0.0.1:1080 %%h %%p\"' %s %s"
		     passwd
		     host-and-path
		     local-dir)))
    (message "cmd=%s" cmd)
    (shell-command cmd)
    )
  )


(defun jms-parse-ssh (s)
  (let ((json (json-read-from-string  (message "%s" (base64-decode-string  (substring  (cdr (car  (json-read-from-string s))) 6))))))
    (message "%S" json)
    (let ((ip (cdr (assoc 'host  (cdr  (assoc 'endpoint json)))))
	  (port (cdr (assoc 'port  (cdr  (assoc 'endpoint json)))))
	  (username (concat "JMS-" (cdr (assoc 'id json))))
	  (passwd (cdr (assoc 'value json)))
	  (real-ip (cdr (assoc 'address (cdr (assoc 'asset json)))))
	  )
      (let ((cmd (format "sshpass -p %s ssh -o StrictHostKeyChecking=no -o ProxyCommand=\"nc -X 5 -x 127.0.0.1:1080 %%h %%p\"  %s@%s -p %d -v" passwd username ip port)))
	(message "cmd=%s" cmd)
	(list  cmd json ip real-ip port username passwd)
	)
      )
    )
  )

(defun jms-ssh-with-ring (buffer-name)
  (let ((cmd (car (jms-parse-ssh (current-kill 0)))))
    (command-with-shell cmd buffer-name)))

(defun jms-parse-to-shell-file (s)
  (let* ((p (jms-parse-ssh s))
	 (cmd (nth 0 p))
	 (ip (nth 3 p))
	 (pwd (nth 1 (string-split (pwd))))
	 (dir (format "jms-ssh-%s" ip))
	 (full-path (concat pwd dir)))
    (shell-command-to-string (format "mkdir -p %s" dir))
    (with-temp-buffer
      (insert cmd)
      (write-region (point-min) (point-max)
		    (format "jms-ssh-%s/ssh.sh" ip)))
    (when (fuzzy-find-buffer full-path)
      (switch-to-buffer (car (fuzzy-find-buffer full-path)))
      (error "eaf terminal exist!" full-path))
    (cd dir)
    (eaf-open-pyqterminal)
    (sleep-for 2)
    (cd pwd)
    ;send cmd
    (with-current-buffer (car (fuzzy-find-buffer full-path))
      (eaf-call-sync "send_key" eaf--buffer-id "sh ssh.sh\n")
      )
    ))

(defun jms-parse-to-shell-file (s)
  (eaf-pyqterminal-run-command-in-dir
   (car  (jms-parse-ssh s))
   (eaf--non-remote-default-directory)
   t))

(defun send-buffer-to-eaf ()
  (interactive)
  (let ((content (base64-encode-string (buffer-string) t))
	(file-name (buffer-name))
	(buffer-name (completing-read "term:" (mapcar (lambda (b) (buffer-name b)) (fuzzy-find-buffer "eaf-Term")))))
    (with-current-buffer buffer-name
      (eaf-call-sync "send_key" eaf--buffer-id (format "echo %s|base64 -d > %s" content file-name))
      ;(switch-to-buffer buffer-name )
      )))

(defun my-send-file-to-eaf ()
  (interactive)
  (let ((file (read-file-name "select file:")))
    (send-file-to-eaf file)))

(defun send-file-to-eaf (file)
  (interactive "Ffile:")
  (let ((content (base64-encode-string (encode-coding-string  (with-temp-buffer
								(insert-file-contents file)
								(buffer-string))
							      'utf-8)
				       t))
	(file-name (file-name-nondirectory file))
	(buffer-name (completing-read "term:" (mapcar (lambda (b) (buffer-name b)) (fuzzy-find-buffer "eaf-Term")))))
    (with-current-buffer buffer-name
      (eaf-call-sync "send_key" eaf--buffer-id "stty -echo")
      (eaf-send-return-key)
      (sleep-for 1)
      (eaf-call-sync "send_key" eaf--buffer-id (format "echo %s|base64 -d > %s" content file-name))
      ;(switch-to-buffer buffer-name )
      (eaf-send-return-key)
      (eaf-call-sync "send_key" eaf--buffer-id "echo transfer ok")
      (eaf-send-return-key)
      (eaf-call-sync "send_key" eaf--buffer-id "stty echo")
      (eaf-send-return-key)
      )))

(defun send-file-to-eaf2 (file buffer-name)
  (let ((content (base64-encode-string (encode-coding-string  (with-temp-buffer
								(insert-file-contents file)
								(buffer-string))
							      'utf-8)
				       t))
	(file-name (file-name-nondirectory file))
	;(buffer-name (completing-read "term:" (mapcar (lambda (b) (buffer-name b)) (fuzzy-find-buffer "eaf-Term"))))
	)
    (with-current-buffer buffer-name
      (eaf-call-sync "send_key" eaf--buffer-id (format "echo %s|base64 -d > %s" content file-name))
      ;(switch-to-buffer buffer-name )
      (eaf-send-return-key)
      )))


(defun send-dir-to-eaf (dir)
  (interactive "Dfile:")
  (message "dir=%S dir:%S" dir
	   (directory-files dir nil))
  (let ((buffer-name (completing-read "term:" (mapcar (lambda (b) (buffer-name b)) (fuzzy-find-buffer "eaf-Term")))))
    (dolist (file (directory-files dir nil))
      (unless (or (string= file ".") (string= file ".."))
	(when (file-exists-p file)
	  (with-current-buffer buffer-name
	    (eaf-call-sync "send_key" eaf--buffer-id (format "echo %s|base64 -d > %s"
							     (base64-encode-string (with-temp-buffer
										     (insert-file-contents (concat dir "/" file))
										     (buffer-string))
										   t)
							     file))
					;(switch-to-buffer buffer-name )
	    (eaf-send-return-key)
	    ))))))

(defun jms-into-ssh (cmd id)
  (message "cmd=%s" cmd)
  (let ((msg (eaf-pyqterminal-run-command-in-dir
	      cmd
	      (eaf--non-remote-default-directory)
	      t)))
					;return buffer-name
    (car (last (string-split msg " ")))))


(defun fetch-url-content-sync (url)
  "Synchronously fetch the content of URL."
  (let ((response-buffer (url-retrieve-synchronously url)))
    (if response-buffer
        (with-current-buffer response-buffer
          (goto-char (point-min))
          (let ((content (buffer-substring (re-search-forward "\n\n") (point-max))))
            (kill-buffer response-buffer)
            content))
      (error "Failed to retrieve URL: %s" url))))

(defun get-all-doc (lst-url)
  (progn
    (generate-new-buffer "interface.el")
    (with-current-buffer "interface.el"
      (insert "'(\n"))
    (dolist (one lst-url)
      (let ((url (nth 1 one))
	    (lst '()))
	(dolist (path (my-assoc 'paths (json-read-from-string (fetch-url-content-sync (string-replace "/doc.html"
												      (my-assoc 'url (aref (json-read-from-string (fetch-url-content-sync (string-replace "/doc.html" "/swagger-resources" url))) 0))
												      url)))))
	  (if (my-assoc 'post path)
	      (progn
		(push  (list (my-assoc 'summary (my-assoc 'post path)) (car path) )
		       lst)
		(with-current-buffer "interface.el"
		  (insert (format "(\"%S\",\"%s\")\n" (car path) (encode-coding-string (my-assoc 'summary (my-assoc 'post path)) 'utf-8-emacs)))
		  )
		)
	    (if (my-assoc 'get path)
		(progn
		  (push  (list  (my-assoc 'summary (my-assoc 'get path)) (car path))
			 lst)
		  (with-current-buffer "interface.el"
		    (insert (format "(\"%S\",\"%s\")\n" (car path) (encode-coding-string (my-assoc 'summary (my-assoc 'get path)) 'utf-8-emacs)))
		    ))
	      nil)))
	lst))
    (with-current-buffer "interface.el"
      (insert ")\n")
      ;(save-buffer)
      )))

(defun get-all-doc2 (lst-url)
  (let ((lst '()))
    (dolist (one lst-url)
      (let ((url (nth 1 one)))
	(dolist (path (my-assoc 'paths (json-read-from-string (fetch-url-content-sync (string-replace "/doc.html"
												      (my-assoc 'url (aref (json-read-from-string (fetch-url-content-sync (string-replace "/doc.html" "/swagger-resources" url))) 0))
												      url)))))
	  (if (my-assoc 'post path)
	      (progn
		(push  (list (format "%s" (my-assoc 'summary (my-assoc 'post path))) (format "%S" (car path)) )
		       lst)
		)
	    (if (my-assoc 'get path)
		(progn
		  (push  (list (format "%s" (my-assoc 'summary (my-assoc 'get path))) (format "%S" (car path)) )
		       lst)
		  )
	      nil)))
	))
    lst))

(defun redis-complet-get (key)
  (eredis-get (completing-read "key:"
			       (eredis-keys (format "*%s*" key)))))
