;; synchronized subscriber 2: wait for HELO message, then signal sync

(use zmq srfi-18)

(define sync (make-socket 'req))
(define sub (make-socket 'sub))

(connect-socket sub "tcp://localhost:5561")
(socket-option-set! sub 'subscribe "")

(connect-socket sync "tcp://localhost:5562")

(let ((msg (receive-message sub)))
  (if (string=? msg "HELO")
      (send-message sync "")
      (error "Expected HELO message")))

(define (receive-all)
  (let loop ((i 0))
    (let ((msg (receive-message sub)))
      (cond ((string=? msg "HELO")
             ;; ignore further HELO messages
             (loop i))
            ((string=? msg "END")
             i)
            (else
             (loop (+ i 1)))))))

(printf "Received ~a updates\n" (receive-all))
