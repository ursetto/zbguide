(use zmq srfi-18)

(define sync (make-socket 'req))
(define sub (make-socket 'sub))

(connect-socket sub "tcp://localhost:5561")
(socket-option-set! sub 'subscribe "")

(connect-socket sync "tcp://localhost:5562")
(thread-sleep! 3)        ;; "ensure" connection to sub is complete (takes > 1 sec here)
(send-message sync "")   ;; signal sync

(define (receive-all)
  (let loop ((i 0))
    (let ((msg (receive-message sub)))
      ;; (when (= 0 (modulo i 50000))
      ;;   (print "recv msg " i))
      (if (string=? msg "END")
          i
          (loop (+ i 1))))))

(printf "Received ~a updates\n" (receive-all))
