;; synchronized publisher : send 1M messages to subscribers to :5561 after
;;    all expected subscribers tell :5562 they are ready
(use zmq)

(define +subscribers-expected+ 10)

(define sync (make-socket 'rep))
(define pub (make-socket 'pub))
(bind-socket pub "tcp://*:5561")
(bind-socket sync "tcp://*:5562")

(do ((i 0 (+ i 1)))
    ((>= i +subscribers-expected+))
  (receive-message sync)
  (print "Synced subscriber " (+ i 1))
  (send-message sync ""))

(do ((i 0 (+ i 1)))
    ((>= i 1000000))
  (send-message pub "Rhubarb"))

(send-message pub "END")


