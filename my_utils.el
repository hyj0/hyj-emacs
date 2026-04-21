;生产者 消费者
(defun make-fifo ()
  (list nil nil))

(defun fifo-empty-p (fifo)
  (null (car fifo)))

(defun fifo-enqueue (element fifo)
  (let ((cell (list element)))
    (if (fifo-empty-p fifo)
	(setf (car fifo) cell
	      (cdr fifo) cell)
      (setf (cdr (cdr fifo)) cell
	    (cdr fifo) cell)))
  fifo)

(defun fifo-dequeue (fifo)
  (if (fifo-empty-p fifo)
      (error "FIFO is empty"))
  (let ((element (car (car fifo))))
    (setf (car fifo) (cdr (car fifo)))
    (if (null (car fifo))
	(setf (cdr fifo) nil))
    element))
;check empty
(defun fifo-size (fifo)
  (length (car fifo)))


(when nil
  (defvar *buffer-fifo* (make-fifo))
  (defun buffer-producer (element)
    (fifo-enqueue element *buffer-fifo*))
  (defun buffer-consumer ()
    (fifo-dequeue *buffer-fifo*))

  (buffer-producer "2")
  (fifo-size *buffer-fifo*)
  (buffer-consumer )
  )

;((name func (make-fifo))
(defvar *my-delay-task-list* nil)
(defun my-delay-task-add (name func)
  "Add a new delayed task to the list."
  (let ((entry (list name func (make-fifo))))
    (setf *my-delay-task-list* (nconc *my-delay-task-list* (list entry)))
    entry)
  )

(defun my-delay-task-put (name event)
  "Add an event to the task's queue."
  (let ((task (assoc name *my-delay-task-list*)))
    (when task
      (fifo-enqueue event (nth 2 task)))))


(defvar *my-delay-task-timer* (run-with-idle-timer
			       2 t
			       (lambda ()
				 (dolist (task *my-delay-task-list*)
				   (let ((name (nth 0 task))
					 (func (nth 1 task))
					 (queue (nth 2 task)))
				     (when (> (fifo-size queue) 0)
				       (let ((event (fifo-dequeue queue)))
					 (funcall func event)))))
				 )))
(cancel-timer *my-delay-task-timer*)

					;test
(my-delay-task-add 'task1 (lambda (s)
			    (message "%s" s)))
(my-delay-task-put 'task1 "world")
