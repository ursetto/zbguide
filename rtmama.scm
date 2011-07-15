;;
;;  Custom routing Router to Mama (ROUTER to REQ)
;;
;;  While this example runs in a single process, that is just to make
;;  it easier to start and stop the example. Each thread has its own
;;  context and conceptually acts as a separate process.
;;

(use zmq random-bsd data-structures)
(include "zhelpers.scm")

(define +num-workers+ 10)

;;; task

(define (worker-task)
  (let* ((ctx (make-context 1))
         (worker (make-socket 'req ctx)))
    ;; We set the socket identity to a random string as in the original;
    ;; but we can safely send and receive NULs so it's not required.
    (randomize-socket-identity! worker)
    (connect-socket worker "ipc://routing.ipc")

    (let loop ((total 0))
      (send-message worker "ready")
      (let ((workload (receive-message* worker)))
        (if (string=? workload "END")
            (print "Processed: " total " tasks")
            (begin (thread-millisleep! (+ 1 (random 1000)))
                   (loop (+ total 1))))))
    
    (close-socket worker)
    (terminate-context ctx)))

;;; main

(define client (make-socket 'xrep))    ;; FIXME: router
(bind-socket client "ipc://routing.ipc")

(define workers
  (list-tabulate +num-workers+
                 (lambda (i) (make-thread worker-task
                                     (conc "worker" i)))))

(for-each thread-start! workers)

(dotimes (i (* 10 +num-workers+))
  ;; LRU worker is next waiting in queue
  (let ((address (receive-message* client)))
    (receive-message* client)   ;; discard empty frame
    (receive-message* client)   ;; discard ready message
    ;; (print "sending to address " address)
    (send-multipart-message client address ""
                            "This is the workload")))

;; Now ask mamas to shut down and report their results
(dotimes (i +num-workers+)
  (let ((address (receive-message* client)))
    (receive-message* client)
    (receive-message* client)
    (send-multipart-message client address ""
                            "END")))

(close-socket client)
(terminate-context (zmq-default-context))

(for-each thread-join! workers)          ;; wait for workers




#|
Processed: 10 tasks
Processed: 13 tasks
Processed: 9 tasks
Processed: 14 tasks
Processed: 9 tasks
Processed: 10 tasks
Processed: 9 tasks
Processed: 10 tasks
Processed: 7 tasks
Processed: 9 tasks

real    0m5.078s
|#
