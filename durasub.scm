(use zmq srfi-18)

(define sync (make-socket 'req))
(define sub (make-socket 'sub))

(socket-option-set! sub 'subscribe "")
(socket-option-set! sub 'identity "Hello")   ;; the durable part (must occur before connect)
(connect-socket sub "tcp://localhost:5565")

(connect-socket sync "tcp://localhost:5564")
;;(thread-sleep! 1)        ;; necessary?  zguide does not use
(send-message sync "")   ;; signal sync

(let loop ((i 0))
  (let ((msg (receive-message sub)))
    (print msg)
    (if (string=? msg "END")
        'done
        (loop (+ i 1)))))


