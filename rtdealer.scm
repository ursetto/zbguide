(use zmq random-bsd srfi-18)

;; Custom routing Router to Dealer (ROUTER to DEALER)
;; While this example runs in a single process, that is just to make
;; it easier to start and stop the example. Each thread has its own
;; context and conceptually acts as a separate process.

(define (make-worker id)        ;; ID: Socket identity (string)
  (lambda ()
    (let* ((context (make-context 1))
           (worker (make-socket 'xreq context)))       ;; FIXME: 'dealer
      (socket-option-set! worker 'identity id)
      (connect-socket worker "ipc://routing.ipc")
      (let loop ((total 0))
        (if (string=? (receive-message* worker)
                      "END")
            (print id " received: " total)
            (loop (+ total 1))))
      (close-socket worker)
      (terminate-context context))))

;;; main

(define client (make-socket 'xrep))                   ;; FIXME: 'router
(bind-socket client "ipc://routing.ipc")

(define A (thread-start! (make-worker "A")))
(define B (thread-start! (make-worker "B")))

;; Wait for threads to connect, since otherwise the messages
;; we send won't be routable.
(thread-sleep! 1)

(do ((i 0 (+ i 1)))
    ((>= i 1000))
  ;; Send 1000 tasks scattered to A twice as often as B
  (send-message client
                (if (> (random 3) 0) "A" "B")
                send-more: #t)
  (send-message client "This is the workload"))

(send-message client "A" send-more: #t)
(send-message client "END")
(send-message client "B" send-more: #t)
(send-message client "END")

;;; finish

(close-socket client)
(terminate-context (zmq-default-context))
(for-each thread-join! (list A B))




#|
$ ./rtdealer
B received: 331
A received: 669

$ ./rtdealer
B received: 324
A received: 676

$ ./rtdealer
B received: 343
A received: 657

|#

