;; Least-recently used (LRU) queue device
;; Clients and workers are shown here in-process
;;
;; While this example runs in a single process, that is just to make
;; it easier to start and stop the example. Each thread has its own
;; context and conceptually acts as a separate process.

;; This contains only the front- and backend portion of the LRU queue.
;; For the polling broker see lruqueue-broker.scm.

(use zmq matchable)
(include "zhelpers.scm")

(define +num-clients+ 10)
(define +num-workers+ 3)

;; Basic request-reply client using REQ socket

(define (client-task)
  (let* ((context (make-context 1))
         (client (make-socket 'req)))
    ;; Not necessary unless you want printable IDs for debugging:
    (randomize-socket-identity! client)
    (connect-socket client "ipc://frontend.ipc")
    (send-message client "HELLO")
    (print "Client: " (receive-message* client))
    (close-socket client)
    (terminate-context context)))

;; Worker using REQ socket to do LRU routing

(define (worker-task)
  (let* ((context (make-context 1))
         (worker (make-socket 'req)))
    ;; Not necessary unless you want printable IDs for debugging:
    (randomize-socket-identity! worker)
    (connect-socket worker "ipc://backend.ipc")
    (send-message worker "READY")

    ;; Read and save all frames until we get an empty frame
    ;; In this example there is only one, but it could be more
    (forever
     (match (receive-multipart-message worker)
            ((address "" reply)
             (print "Worker: " reply)
             (send-multipart-message worker `(,address "" "OK")))))))

;;; main

(define (spawn n proc #!optional desc)
  (map thread-start!
       (list-tabulate n (lambda (i) (if desc
                                   (make-thread proc (conc desc i))
                                   (make-thread proc))))))

(define clients (spawn +num-clients+ client-task 'client))
(define workers (spawn +num-workers+ worker-task 'worker))

;; Finish once all clients have received replies.
(for-each thread-join! clients)

