
(add-to-list 'load-path (concat (my-home-dir) "gptel/"))

(require 'gptel)
(require 'gptel-curl)
(require 'gptel-openai-extras)
(require 'gptel-gemini)
(require 'gptel-transient)

(setq gptel-curl--common-args
      (append gptel-curl--common-args  (list "--proxy"  "http://localhost:8118")))

(defvar *my-llmlite-host* "10.9.0.164:8080")
(defvar *my-llmlite-key* "123")


(defun my-gptel-make-llmlite-backend (name models)
  (setq
   gptel-backend (gptel-make-openai name
		   :models models
		   :host *my-llmlite-host*
		   :key *my-llmlite-key*
		   :stream t
		   :protocol "http"
		   :endpoint "/chat/completions")))


(setq
 gptel-backend (gptel-make-openai "openai duckgo"
		 :models '(gpt-4o-mini)
		 :host "10.9.0.164:8080"
		 :key "aaaa"
		 :stream t
		 :protocol "http"
		 :endpoint "/chat/completions"))

(setq
 gptel-backend (gptel-make-deepseek "deepseek-genlot"
		 :models '(deepseek-r1:70b)
		 :host "10.9.0.164:4000"
		 :key "no_key"
		 :stream t
		 :protocol "http"
		 :endpoint "/chat/completions"))


(setq  gptel-log-level 'debug)

(defun my-gptel ()
  (interactive)
  (let ((name  (completing-read "select llm:" gptel--known-backends)))
    (setq gptel-model (car (gptel-backend-models (my-assoc name gptel--known-backends))))
    (setq gptel-backend
	  (my-assoc name gptel--known-backends))
    (switch-to-buffer
     (gptel (format "*gptel-%s*" name)
	    (gptel-backend-key (my-assoc name gptel--known-backends)) nil nil))))


(defun my-get-sexp ()
  (let ((sexp-str ""))
    (if (and (bound-and-true-p evil-mode) (evil-normal-state-p))
	(progn
	  (message "evil-normal-state")
	  (evil-insert-state)
	  (goto-char (+ 1 (point)))
	  (setq sexp-str (buffer-substring  (save-excursion (backward-sexp) (point)) (point)))
	  (evil-normal-state))
      (setq sexp-str (buffer-substring  (save-excursion (backward-sexp) (point)) (point))))
    sexp-str))


(defun my-eval-last-sexp-handle-err ()
  (interactive)
  (let* ((sexp-str (my-get-sexp))
	(res (condition-case err
		 (progn
		   (eval (read sexp-str))
		   )
	       (error (concat (format  " An error occurred: %S" err )
					;(backtrace-to-string (backtrace-get-frames 'backtrace))
			      )))))
    (save-excursion
      (goto-char (point-max))
      (insert (format "\nrun:%s\n" sexp-str))
      (insert (format "%s" res))
      (insert "\n")))
  )


(define-key gptel-mode-map (kbd "<f5>") 'my-eval-last-sexp-handle-err)
(define-key gptel-mode-map (kbd "C-<return>") 'gptel-send)


(defun my-markdown-extract-and-run-code-block ()
  (interactive)
  (let ((cur-point (point)))
    (save-excursion
      (goto-char (point-min))
      (let (found-and-processed) ; 添加一个变量来标记是否找到并处理了 block
	(while (and (not found-and-processed) (re-search-forward "^```\\([a-zA-Z-]+\\)?\n" nil t))
          (let* ((start (match-beginning 0))
		 (lang (if (match-string 1) (match-string 1) ""))
		 (code-start (match-end 0))
		 (end (re-search-forward "^```\n" nil t))
		 (code (buffer-substring code-start (1- (match-beginning 0)))))
	    (message "[%d %d] %d" start end cur-point)
            ;; 检查光标是否在 block 内
            (if (and (>= cur-point start) (<= cur-point end))
		(progn
                  (message "Found code block at cursor: %s" lang)
                  (message "Code: %s" code)

                  ;; 创建新 buffer
                  (let ((new-buffer (generate-new-buffer "Code Block"))
			(cur-buffer (current-buffer)))
                    (switch-to-buffer new-buffer)
                    (insert code)
                    ;; 设置 major mode
                    (cond
                     ((string= lang "python") (python-mode))
                     ((or (string= lang "shell") (string= lang "sh")) (sh-mode))
                     ((or (string= lang "emacs-lisp") (string-match-p "elisp" lang)) (emacs-lisp-mode))
                     (t (fundamental-mode))) ; 默认模式
                    ;; 运行代码 (示例，需要根据 lang 调整)
                    (cond
                     ((string= lang "python") (elpy-shell-send-region-or-buffer))
                     ((or (string= lang "shell") (string= lang "sh"))
		      (progn
			(shell-command-on-region (point-min) (point-max) "sh -x" new-buffer nil)
			(let ((str (buffer-string)))
			  (with-current-buffer cur-buffer
			    (goto-char (point-max))
			    (insert "\n")
			    (insert str))
			  (switch-to-buffer cur-buffer)
			  (evil-delete-buffer new-buffer)))
		      )
                     ((or (string= lang "emacs-lisp") (string-match-p "elisp" lang))
		      (eval-buffer))
                     (t (message "No runner defined for language %s" lang))))
                  (setq found-and-processed t)) ; 设置标记，停止循环
              (message "Skipping code block, cursor not inside."))))
	(if (not found-and-processed)
            (message "No code block found at cursor.")))
      (message "Done!"))))

(require 'markdown-mode)

(defun my-markdown--browse-url (org-fun url)
  (if (= 0 (string-match-p "http" "https://"))
      (eaf-open-browser url)
    (funcall org-fun url))
  )

(advice-add  'markdown--browse-url :around #'my-markdown--browse-url)
;(advice-remove  'markdown--browse-url #'my-markdown--browse-url)


(when nil
  (add-to-list 'gptel-tools
	       (gptel-make-tool
		:name "read_buffer"                    ; javascript-style snake_case name
		:function (lambda (buffer)                  ; the function that will run
			    (unless (buffer-live-p (get-buffer buffer))
			      (error "error: buffer %s is not live." buffer))
			    (with-current-buffer  buffer
			      (buffer-substring-no-properties (point-min) (point-max))))
		:description "return the contents of an emacs buffer"
		:args (list '(:name "buffer"
				    :type string            ; :type value must be a symbol
				    :description "the name of the buffer whose contents are to be retrieved"))
		:category "emacs"))
  (add-to-list 'gptel-tools
	       (gptel-make-tool
		:name "create_file"                    ; javascript-style  snake_case name
		:function (lambda (path filename content)   ; the function that runs
			    (let ((full-path (expand-file-name filename path)))
			      (with-temp-buffer
				(insert content)
				(write-file full-path))
			      (format "Created file %s in %s" filename path)))
		:description "Create a new file with the specified content"
		:args (list '(:name "path"             ; a list of argument specifications
				    :type string
				    :description "The directory where to create the file")
			    '(:name "filename"
				    :type string
				    :description "The name of the file to create")
			    '(:name "content"
				    :type string
				    :description "The content to write to the file"))
		:category "filesystem"))
  (progn
    (kill-buffer (car (fuzzy-find-buffer "*open-inter")))
    (open-interpreter-action))
  )
