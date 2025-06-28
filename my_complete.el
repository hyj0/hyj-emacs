; -*- lexical-binding: t -*-

(require 'company)

(defvar *my-company-prefix* nil)

(defun my-company-capf-around (org-fun command &optional arg &rest _args)
  ;(message "my-company-capf-around=%s %s %s" command arg _args)
  (let ((ret (apply org-fun command arg _args)))
    ;(message "my-company-capf-around ret=%s" ret)
    ret))

(defun my-company-capf-around (org-fun command &optional arg &rest _args)
					;(message "my-company-capf-around=%s %s %s" command arg _args)
  (let ((ret (funcall org-fun command arg _args)))
					;(message "my-company-capf-around ret=%s" ret)
    (if (and  (eq 'prefix command) (not (eq nil  ret)) (not (eq ret 'stop))
	      (not  (eq major-mode 'scheme-mode)) (not (eq major-mode 'c-mode)) (not (eq major-mode 'c++-mode)))
	(let ((ret1 (add-star-between-str ret)))
	  (message "prefix %s-->%s" ret ret1)
	  (setq *my-company-prefix* (list ret ret1))
	  ret1)
      ret)))


(advice-add 'company-capf :around #'my-company-capf-around)
(advice-remove 'company-capf  #'my-company-capf-around)

;(advice-add 'company-dabbrev-code :around #'my-company-capf-around) ;for scm
;(advice-remove 'company-dabbrev-code  'my-company-capf-around)

(debug-on-entry 'my-company-capf-around)
(cancel-debug-on-entry 'my-company-capf-around)


(defun my-company--insert-candidate (candidate prefix)
  (when (> (length candidate) 0)
    (setq candidate (substring-no-properties candidate))
    ;; XXX: Return value we check here is subject to change.
    (if (eq (company-call-backend 'ignore-case) 'keep-prefix)
	(let ((s (company-strip-prefix candidate prefix)))
	  (message "company-strip-prefix=%s"  (company-strip-prefix candidate prefix))
          (insert (company-strip-prefix candidate prefix)))
      (unless (equal prefix candidate)
	(message "company-prefix=%s" company-prefix)
	(message "prefix=%s" prefix)
	(message "candidate=%s" candidate)
	(message "*my-company-prefix*=%s" (prin1-to-string *my-company-prefix*))
	(when t
	  (if (eq nil *my-company-prefix*)
              (delete-region (- (point) (length prefix)) (point))
	    (let ((start  (- (point) (length (car (car *my-company-prefix*)))))
		  (end  (point)))

	      (message "del reg=(%d %d)" start end)
	      (delete-region start end))))
	(setq *my-company-prefix* nil)
        (insert candidate)
	))))

(defun my-company--insert-candidate-around (org-fun &rest _args)
  (message "my-company--insert-candidate-around=%s prefix=%s" _args (prin1-to-string *my-company-prefix*))
  (if (and  *my-company-prefix* (stringp (car *my-company-prefix*)))
      (progn
	(apply 'my-company--insert-candidate _args)
	(setq *my-company-prefix* nil))
    (let ((ret (apply org-fun  _args)))
      (message "my-company--insert-candidate-around ret=%s" ret)
      ret)))

(advice-add 'company--insert-candidate :around #'my-company--insert-candidate-around)
(advice-remove 'company--insert-candidate  #'my-company--insert-candidate-around)

(debug-on-entry 'company--insert-candidate)
(cancel-debug-on-entry 'company--insert-candidate)



(defun my-string-len< (x y)
  "Like `string<', but operate on CARs when given cons cells."
  ;(message "my-string-len< x=%S y=%S" x y)
  (let ((len-x (length x))
	(len-y (length y)))
    (if (= len-x len-y)
	(ivy-string< x y)
      (< len-x len-y))))

(when nil
   (cond ((< len-x len-y) -1)
	    ((> len-y len-x) 1)
	    (t (string< x y))
	    ))

;org
(setq ivy-sort-functions-alist
	     '((read-file-name-internal . ivy-sort-file-function-default)
	       (t . my-string-len<)))

(setq ivy-sort-functions-alist
      '((t . my-string-len<)))


(setq ivy-sort-functions-alist
      '((execute-extended-command . my-string-len<)
	(describe-function . my-string-len<)
	(t . my-string-len<)))
;(setq completing-read-function 'ivy-completing-read)


					;(ivy-read "Select a letter: " '("bb" "c" "a") :sort t)
					;(ivy-read "Select a letter: " '("bb" "c" "a") :sort #'my-string-len<)

(setq company-minimum-prefix-length 2)

(defun my-company-trans (lst)
  (sort lst 'my-string-len<))

(setq company-transformers '(my-company-trans))

(when (not (fboundp 'string-replace))
  (defun string-replace (what with in)
    (replace-regexp-in-string (regexp-quote what) with in nil 'literal)))


(defun add-star-between-str (str)
  (cond ((stringp str)
	 (let ((ret
		(mapconcat
		 'identity
		 (split-string str "" t) "*")))
	   (message "ret=%s" ret)
	   (if (or (= 1 (length ret))
		   (and (> (length ret) 0) (string-equal "/" (substring ret 0 1))))
	       ret
	     (concat "*" (string-replace "**" "*" (string-replace "***" "*" ret))))))
	((listp str)
	 (mapcar #'add-star-between-str str))
	(t str)
	))

(defun add-star-between-str2 (str)
  (if (stringp str)
      (let ((ret
	     (mapconcat
	      'identity
	      (split-string str "" t) ".*")))
	(if (or (= 1 (length ret))
		(and (> (length ret) 0) (string-equal "/" (substring ret 0 1))))
	    ret
	  (setq ret (concat "" (string-replace "**" "*" (string-replace "***" "*" ret)))))
	;(message "ret=%s" ret)
	ret
	)
    str))

(defun my-string-match (regexp str)
  (let ((start-pos (string-match regexp str)))
    (if start-pos
	(if (= 1 (length regexp))
	    (cons start-pos 1)
	  (let* ((last-reg (format "%c" (aref regexp (1- (length regexp)))))
		 (endpos (string-match last-reg str (1+ start-pos)))
		 (last-end-pos endpos))
	    (while endpos
	      (if (string-match-p regexp (substring str start-pos endpos))
		  (setq endpos nil)
		(progn
		  (setq last-end-pos endpos)
		  (setq endpos  (string-match last-reg str (1+ last-end-pos)))))
	      )
	    (cons start-pos (- last-end-pos start-pos))))
      nil)))

(when (os-is-linux)
    (with-eval-after-load 'eglot
      (add-to-list 'eglot-server-programs
		   '(scheme-mode . ("scheme" "--script" "/data/projector/CLionProjects/scheme-langserver/run.ss" "/data/projector/scheme-langserver.log"))
		   )))

(require 'eglot)
(when (os-is-linux)
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 (cons 'c++-mode  (split-string "sudo docker exec -i lsp-docker ccls"))
		 ;(cons 'c++-mode (split-string "/data/projector/clion-2023.1.6/bin/clion.sh lsp-server ."))
		 ;(cons 'c++-mode '("127.0.0.1" 8989))
		 )))
(when (os-is-linux)
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 (cons 'c-mode  (split-string "sudo docker exec -i lsp-docker ccls"))
		 ;(cons 'c-mode (split-string "/data/projector/clion-2023.1.6/bin/clion.sh lsp-server ."))
		 ;(cons 'c-mode '("127.0.0.1" 8989))
		 )))
(require 'ivy-posframe)
(ivy-posframe-mode 1)

(require 'recentf)
(setq recentf-max-saved-items 1000     ; é»?è®?20ï¼?å»ºè??è®¾ç½®100-500
      recentf-auto-cleanup 'never     ; ?³é?????¨æ???ï¼??¿å??è¿??©å???¤è?°å?ï¼?
      recentf-save-file "~/.emacs.d/recentf")  ; ??ä¹???å­??¨è·¯å¾?

;; é«?çº§è?æ»¤è???ï¼?????ï¼?
;(setq recentf-exclude '("/ssh:" "/tmp/" ".gz" "COMMIT_EDITMSG")) ; ???¤ç?¹å??è·?å¾?

;; æ¯?15???????¨ä?å­?ï¼?é»?è®?5????ï¼?
(run-at-time nil (* 3 60) 'recentf-save-list)

(recentf-mode 1)



					;https://emacs-china.org/t/emacs-autocomplete/24384/8
					; use https://github.com/elp-revive/company-mode
(add-to-list 'load-path (concat (my-home-dir) "company-fuzzy/"))
(require 'company-fuzzy)
(global-company-fuzzy-mode 1)

(setq company-fuzzy-sorting-function (lambda (lst)
				       (sort lst #'my-string-len<)))
;ä¸??¢å½±??äº?elpy
(let ((elpa-dir (expand-file-name "~/.emacs.d/elpa/"))
      (prefix "elpy"))
  (when (file-directory-p elpa-dir)
    (dolist (dir (directory-files elpa-dir t "^" prefix))
      (when (and (file-directory-p dir)
                 (string-prefix-p prefix (file-name-nondirectory dir)))
        (add-to-list 'load-path dir)))))
(require 'elpy)



(defun my-ivy-read (prompt history-candidates)
  (interactive)
  (ivy-read
   "[EAF/browser] Search || URL || History: "
   (lambda (str)
     (let ((candidates history-candidates)
	   (start-time (float-time (current-time))))
       (or
	(when (< (length str) 1)
	  candidates)
	(if nil
	    (append
	     (seq-filter (lambda (s)
			   (if (> (- (float-time (current-time)) start-time) 0.6)
			       nil
			     (string-match-p (regexp-quote str) s)))
			 candidates)
	     (sort (seq-filter (lambda (s)
				 (if  (> (- (float-time (current-time)) start-time) 0.6)
				     nil
				   (string-match-p (add-star-between-str2 (regexp-quote str)) s)))
			       candidates)
		   #'my-string-len<))
	  (progn
	    (mapcar
	     (lambda (one)
	       (nth 1 one))
	     (sort
	      (cl-remove-if 'null (mapcar (lambda (s)
					    (if (> (- (float-time (current-time)) start-time) 1.2)
						nil
					      (let ((ret (my-string-match (add-star-between-str2 str) s)))
						(if ret
						    (list (cdr ret) s)
						  nil))))
					  history-candidates))
	      (lambda (a b)
		(< (car a) (car b)))))
	    )))))
   :dynamic-collection t)
  )



(defun my-open-history ()
  (interactive)
  (let ((eaf-url-history (mapcar (lambda (one)
				   (list one (list 'eaf one)))
				 (let* ((browser-history-file-path
					 (concat eaf-config-location
						 (file-name-as-directory "browser")
						 (file-name-as-directory "history")
						 "log.txt"))
					(history-pattern "^\\(.+\\)??\\(.+\\)??\\(.+\\)$")
					(history-file-exists (file-exists-p browser-history-file-path))
					(history-candidates (if history-file-exists
								(mapcar
								 (lambda (h) (when (string-match history-pattern h)
									       (format "[%s] ?? %s" (match-string 1 h) (match-string 2 h))))
								 (with-temp-buffer (insert-file-contents browser-history-file-path)
										   (split-string (buffer-string) "\n" t)))
							      nil))

					)
				   history-candidates
				   )))
	(recentf-history (mapcar (lambda (one)
				   (list one (list 'recentf one)))
				 recentf-list))
	(ssh-auinfo (mapcar (lambda (one)
			      (list (format "%s --terminal" (car one)) (list 'auinfo one)))
			    (mapcar (lambda (one) (list (format "/%s:%s@%s:~/" (plist-get one :port) (plist-get one :user) (plist-get one :host)) one))  (auth-source-search :max 100 ))))
	(ssh-auinfo-insert (mapcar (lambda (one)
				     (list (concat (car one) "--insert") (list 'auinfo-insert one)))
				   (mapcar (lambda (one) (list (format "/%s:%s@%s:~/" (plist-get one :port) (plist-get one :user) (plist-get one :host)) one))  (auth-source-search :max 100 ))))
	(bookmark-list (mapcar (lambda (one)
				 (let ((key  (concat (car one) "-->" (my-assoc 'filename one))))
				   (list key (list 'bookmark one))))
			       (progn
				 (bookmark-maybe-load-default-file)
				 (cl-remove-if-not
				  (lambda (entry)
				    (bookmark-prop-get entry 'eaf-app))
				  bookmark-alist)
				 )))
	(my-functions (mapcar (lambda (one)
				(list one (list 'my-functions one)))
			      (if nil
				  (all-completions "my-" obarray 'fboundp)
				(mapcan
				 (lambda (filename)
				   (let ((defun-names '()))
				     (with-temp-buffer
				       (insert-file-contents filename)
				       (goto-char (point-min))
				       (while (re-search-forward "^(defun \\([a-zA-Z0-9_-]+\\)" nil t)
					 (add-to-list 'defun-names (match-string 1)))
				       )
				     defun-names))
				 (directory-files (my-home-dir) t "^my.*\\.el$")))))
	(my-buffer-list (mapcar (lambda (one)
				  (list (concat (buffer-name one) "-->buffer") (list 'buffer-name one))
				  )
				(buffer-list))))
    (let ((all-collection (append eaf-url-history my-buffer-list recentf-history ssh-auinfo ssh-auinfo-insert bookmark-list my-functions)))
      (let* ((select (my-ivy-read "select:" (mapcar (lambda (one) (car one)) all-collection)))
	     (value (car (my-assoc select all-collection)))
	     (key (car value))
	     (value2 (car (cdr value))))
	(message "%S-->%S --> %S" select value value2)
	(cond ((eq key 'auinfo)
	       (let ((info (car (cdr value2))))
		 (ssh-eaf (plist-get info :host) (plist-get info :user) (auth-info-password info) t)
					;info
		 ))
	      ((eq key 'buffer-name)
	       (switch-to-buffer value2))
	      ((eq key 'auinfo-insert)
	       (let ((auinfo-str (car value2)))
		 (message "auinfo-str=%S" auinfo-str)
		 (insert auinfo-str)
		 ))
	      ((eq key 'eaf)
	       (progn
		 (let* ((history value2)
			(history-url
			 (eaf-is-valid-web-url (when (string-match "??\s\\(.+\\)$" history)
						 (match-string 1 history)))))
		   (cond (history-url (eaf-open-browser history-url))
			 ((eaf-is-valid-web-url history) (eaf-open-browser history))
			 (t (eaf-search-it history))))))
	      ((eq key 'recentf)
	       (funcall recentf-menu-action value2)
	       )
	      ((eq key 'bookmark)
	       (let ((select (my-assoc 'filename value2)))
		 (cond ((eaf-is-valid-web-url select) (eaf-open-browser select))
		       ((and (file-exists-p select) (file-readable-p select))
			(find-file select))
		       (t (message "can not open %s" select)))))
	      ((eq key 'my-functions)
	       (message "funcall %s" value2)
	       (condition-case error
		   (funcall (intern value2))
		 (error
		  (message "cannot funcall %s, try execute-extended-command" value2)
		  (execute-extended-command nil value2))))
	      (select
	       (cond ((eaf-is-valid-web-url select) (eaf-open-browser select))
		     ((and (file-exists-p select) (file-readable-p select))
		      (find-file select))
		     (t (message "can not open %s" select)))))))
    ))


(global-set-key (kbd "<f3>") 'my-open-history)

(require 'minuet)
(setenv "LILTELLM_API_KEY" "sk-123")
(use-package minuet
    :config
    (setq minuet-provider 'openai-compatible)
    (setq minuet-request-timeout 2.5)
    (setq minuet-auto-suggestion-throttle-delay 1.5) ;; Increase to reduce costs and avoid rate limits
    (setq minuet-auto-suggestion-debounce-delay 0.6) ;; Increase to reduce costs and avoid rate limits

    (plist-put minuet-openai-compatible-options :end-point "http://10.9.0.164:4000/chat/completions")
    (plist-put minuet-openai-compatible-options :api-key "LILTELLM_API_KEY")
    (plist-put minuet-openai-compatible-options :model "gemini-2.0-flash")
    ;(plist-put minuet-openai-compatible-options :model "deepseek-r1:70b")
    ;(plist-put minuet-openai-compatible-options :model "deepseek/deepseek-r1/community")


    ;; Prioritize throughput for faster completion
    (minuet-set-optional-options minuet-openai-compatible-options :provider '(:sort "throughput"))
    (minuet-set-optional-options minuet-openai-compatible-options :max_tokens 128)
    (minuet-set-optional-options minuet-openai-compatible-options :top_p 0.9))

(defvar  *my-eaf-term-screen-data* nil)

(defun my-minuet-complete-with-minibuffer ()
  (interactive)
  (if (and (eq major-mode 'eaf-mode) (string= eaf--buffer-app-name "pyqterminal"))
      (progn
	(setq *my-eaf-term-screen-data* nil)
	(my-eaf-exec-pycode (with-temp-buffer
			      (insert-file-contents (concat (my-home-dir) "my_eaf_term_content.py"))
			      (buffer-string)))
	(while (not *my-eaf-term-screen-data*)
	  (sleep-for 0.2))
	(let ((x (nth 0 *my-eaf-term-screen-data*))
	      (y (nth 1 *my-eaf-term-screen-data*))
	      (content (nth 2 *my-eaf-term-screen-data*))
	      (cur-buffer (current-buffer)))
	  (progn
	    (erase-buffer )
	    (insert content)
					;point to x y
	    ;(goto-char (point-min))
	    ;(forward-line y)
	    ;(forward-char x)
	    (goto-char (point-max))
	    (let ((old-point (point))
		  (new-point (point))
		  (old-content-len (point-max))
		  (new-content-len (point-max)))
	      (let* ((complete-fn (intern (format "minuet--%s-complete" minuet-provider)))
		     (advice-wraper (lambda (orgin context callback)
				      (funcall orgin context
					       (lambda (items)
						 (with-current-buffer cur-buffer
						   (goto-char (point-min)))
						 (funcall callback items)
						 (message "callback done %S" complete-fn)
						 (with-current-buffer cur-buffer
						   (setq new-point (point))
						   (setq new-content-len (point-max))
						   (message "old:%d new:%d" old-content-len new-content-len)
						   (message "old-point:%d new-point:%d" old-point new-point)
					;get content
					;(message "diff:%S" (buffer-substring-no-properties old-point new-point))
						   (let ((diff  (buffer-substring-no-properties (point-min) (+ (point-min) (- new-content-len old-content-len)))))
						     (message "diff2:%S" diff)
						     (eaf-call-sync "send_key" eaf--buffer-id diff)))
						 )))))
		(advice-add complete-fn :around advice-wraper)
		(unwind-protect
		    (minuet-complete-with-minibuffer)
		  (advice-remove complete-fn advice-wraper))
		)

	      )
	    )
	  )
	)
    (minuet-complete-with-minibuffer))
  )


(global-set-key (kbd "<f2>") 'my-minuet-complete-with-minibuffer)


(when t
  (setq tramp-ssh-controlmaster-options "-o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ProxyCommand='nc -X 5 -x 127.0.0.1:1080 %%h %%p'")
					;tramp complete in eshell
  (defun my-complete-tramp-authinfo ()
    (interactive)
    (let ((sp  (mapcar (lambda (one) (format "/%s:%s@%s:~/" (plist-get one :port) (plist-get one :user) (plist-get one :host)))  (auth-source-search :max 1000 ))))
      (insert  (completing-read "authinfo:" sp))))
  (add-hook 'eshell-mode-hook
	    (lambda ()
	      (message "eshell-mode-hook!!")
					;(eshell/alias "ll" "ls -al")
					;(company-fuzzy-mode nil)
	      (run-with-idle-timer
	       3
	       nil
	       (lambda (buffer)
		 (message "eshell-mode-hook!! in %S" buffer)
		 (when (get-buffer buffer)
		   (with-current-buffer buffer
		     (company-fuzzy-mode 0))))
	       (current-buffer))
	      ))
  )

(defun my-eaf-term-in-pwd ()
  (interactive)
  (let ((path default-directory))
    (if (string-match "^/ssh:\\([^@]+\\)@\\([a-zA-Z0-9.]+\\)\\(?:#\\([0-9]+\\)\\)?:\\(.+\\)$" path)
	(let* ((user (match-string 1 path))
               (host (match-string 2 path))
               (port (match-string 3 path))
               (directory (match-string 4 path))
	       (info
		(car
		 (auth-source-search :user user  :host host :port "ssh" :max 100))))
	  (if info
	      (let ((default-directory path))
		(ssh-eaf (plist-get info :host) (plist-get info :user) (auth-info-password info) t nil
			 (format "-t 'cd %s && bash'" directory)))
	    (eaf-open-pyqterminal))
	  )
      (eaf-open-pyqterminal))
    )
  )


(defvar *eaf-term-title* nil)

(defun my-eaf-term-in-pwd ()
  (interactive)
  (if (and  (eq major-mode 'eaf-mode ) (string= eaf--buffer-app-name "pyqterminal"))
      (let* ((url (eaf-get-path-or-url))
	     (title (progn
		     (setq *eaf-term-title* nil)
		     (my-eaf-exec-pycode "set_emacs_var('*eaf-term-title*', self.buffer_widget.title)\nprint(self.buffer_widget.title)")
		     (while (not *eaf-term-title*)
		       (sleep-for 0.1))
		     *eaf-term-title*))
	     (path (nth 1 (string-split title ":"))))
	(if (string-match-p " ssh " url)
	    (let ((sp (car
		       (delq nil
			     (mapcar (lambda (one)
				       (when (string-match-p "@" one)
					 one))
				     (string-split url))))))
	      (let ((default-directory (format "/ssh:%s:%s/" sp path)))
		(my-eaf-term-in-pwd0)))
	  (let ((default-directory path))
	    (my-eaf-term-in-pwd0))))
    (my-eaf-term-in-pwd0))
  )

(defun my-eaf-term-in-pwd0 ()
  (let ((path default-directory))
    (if (string-match "^/ssh:\\([^@]+\\)@\\([a-zA-Z0-9.]+\\)\\(?:#\\([0-9]+\\)\\)?:\\(.+\\)$" path)
	(let* ((user (match-string 1 path))
               (host (match-string 2 path))
               (port (match-string 3 path))
               (directory (match-string 4 path))
	       (info
		(car
		 (auth-source-search :user user  :host host :port "ssh" :max 100))))
	  (if info
	      (let ((default-directory path))
		(ssh-eaf (plist-get info :host) (plist-get info :user) (auth-info-password info) t nil
			 (format "-t 'cd %s && bash'" directory)))
	    (eaf-open-pyqterminal))
	  )
      (eaf-open-pyqterminal))
    )
  )


(defun my-aweshell-in-term ()
  (interactive)
  (my-fix-cur-pwd
   (lambda ()
     (aweshell-new)))
  (if (and  (eq major-mode 'eaf-mode ) (string= eaf--buffer-app-name "pyqterminal"))
      (let* ((url (eaf-get-path-or-url))
	     (title (progn
		     (setq *eaf-term-title* nil)
		     (my-eaf-exec-pycode "set_emacs_var('*eaf-term-title*', self.buffer_widget.title)\nprint(self.buffer_widget.title)")
		     (while (not *eaf-term-title*)
		       (sleep-for 0.1))
		     *eaf-term-title*))
	     (path (nth 1 (string-split title ":"))))
	(if (string-match-p " ssh " url)
	    (let ((sp (car
		       (delq nil
			     (mapcar (lambda (one)
				       (when (string-match-p "@" one)
					 one))
				     (string-split url))))))
	      (let ((default-directory (format "/ssh:%s:%s/" sp path)))
		(aweshell-new)))
	  (let ((default-directory path))
	    (aweshell-new))))
    (aweshell-new))
  )


(defun my-find-file-read-args-advice (orig-fun prompt mustmatch)
  (my-fix-cur-pwd
   (lambda ()
     (funcall orig-fun prompt mustmatch))))

(advice-add 'find-file-read-args :around #'my-find-file-read-args-advice)
;(advice-remove 'find-file-read-args #'my-find-file-read-args)

(defun my-fix-cur-pwd (call-back)
  (if (and  (eq major-mode 'eaf-mode ) (string= eaf--buffer-app-name "pyqterminal"))
      (let* ((url (eaf-get-path-or-url))
	     (title (progn
		      (setq *eaf-term-title* nil)
		      (my-eaf-exec-pycode "set_emacs_var('*eaf-term-title*', self.buffer_widget.title)\nprint(self.buffer_widget.title)")
		      (while (not *eaf-term-title*)
			(sleep-for 0.1))
		      *eaf-term-title*))
	     (path (nth 1 (string-split title ":"))))
	(message "url:%S" url)
	(cond
	 ((string-match-p " ssh " url)
	  (let ((sp (car
		     (delq nil
			   (mapcar (lambda (one)
				     (when (string-match-p "@" one)
				       one))
				   (string-split url))))))
	    (let ((default-directory (format "/ssh:%s:%s/" sp path)))
	      (message "dir:%s" default-directory)
	      (funcall call-back))))
	 ((and (string-match-p " ./jms.py " url) (not (string=  (substring default-directory 0 5) "/jms:")))
	  (let ((pwd default-directory))
	    (message "pwd:%s" pwd)
	    ;delete "jms" in tramp-methods
	    (setq tramp-methods
		  (delq (assoc "jms" tramp-methods 'string=) tramp-methods))
	    (add-to-list 'tramp-methods
			 (list "jms"
			       '(tramp-login-program "python")
			       (list 'tramp-login-args (list (list (concat pwd "/jms.py")) '("%h")))
			       '(tramp-remote-shell "/bin/bash")
			       ))

	    (let ((default-directory (format "/jms:%s:%s/"
					     (car (last  (string-split url)))
					     path)))
	      (funcall call-back)))
	      )
	 (t (funcall call-back))))
    (funcall call-back)))


(defun my-read-file-name-around (orig-fun prompt &optional dir default-filename mustmatch initial predicate)
  (interactive)
  (my-fix-cur-pwd
   (lambda ()
     (funcall orig-fun prompt dir default-filename mustmatch initial predicate))))

(advice-add 'read-file-name :around #'my-read-file-name-around)
;(advice-remove 'read-file-name  #'my-read-file-name-around)


(defun my-aweshell-new-around (orig-fun)
  (interactive)
  (if (and  (eq major-mode 'eaf-mode ) (string= eaf--buffer-app-name "pyqterminal"))
      (let* ((url (eaf-get-path-or-url))
	     (title (progn
		      (setq *eaf-term-title* nil)
		      (my-eaf-exec-pycode "set_emacs_var('*eaf-term-title*', self.buffer_widget.title)\nprint(self.buffer_widget.title)")
		      (while (not *eaf-term-title*)
			(sleep-for 0.1))
		      *eaf-term-title*))
	     (path (nth 1 (string-split title ":"))))
	(if (string-match-p " ssh " url)
	    (let ((sp (car
		       (delq nil
			     (mapcar (lambda (one)
				       (when (string-match-p "@" one)
					 one))
				     (string-split url))))))
	      (let ((default-directory (format "/ssh:%s:%s/" sp path)))
		(message "dir:%s" default-directory)
		(funcall orig-fun)))
	  (let ((default-directory path))
	    (funcall orig-fun))))
    (funcall orig-fun))
  )

(advice-add 'aweshell-new :around #'my-aweshell-new-around)
;(advice-remove 'find-file-read-args #'my-find-file-read-args)


(defun my-cliboard-base64-to-file ()
  (interactive)
  (with-temp-buffer
    (insert-buffer  (car (fuzzy-find-buffer "loop-paste-file.txt")))
    (base64-decode-region (point-min) (point-max))
					;write to file
    (write-file
     (read-file-name "file:")
     nil
     )))
