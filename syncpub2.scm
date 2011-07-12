;; synchronized publisher : send HELO messages until all expected subscribers
;;    signal ready on :5562; then send 1M messages to subscribers on :5561

(use zmq)

(define +subscribers-expected+ 20)

(define sync (make-socket 'rep))
(define pub (make-socket 'pub))
(bind-socket pub "tcp://*:5561")
(bind-socket sync "tcp://*:5562")

(define hello (make-thread (lambda () (let loop ()
                                   (send-message pub "HELO")
                                   (thread-sleep! 0.5)
                                   (loop)))))
(thread-start! hello)

(do ((i 0 (+ i 1)))
    ((>= i +subscribers-expected+))
  (receive-message* sync)
  (print "Synced subscriber " (+ i 1))
  (send-message sync ""))

(thread-terminate! hello)  ;; kinda evil!

(do ((i 0 (+ i 1)))
    ((>= i 1000000))
  (send-message pub "Rhubarb"))

(send-message pub "END")

;; Critical -- with high client # program may otherwise exit without flushing the END message.
(close-socket pub)

;; Not so critical.
;;(close-socket sync)
;;(terminate-context (zmq-default-context))

