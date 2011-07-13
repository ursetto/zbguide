;; durable synchronized publisher : send 10 messages to single subscriber on :5564
;;    after subscriber indicates ready on :5565.

;; Warning: If you resume subscription after END is sent, outstanding messages are
;; not received.  The native C code exhibits the same behavior.

(use zmq srfi-18)

(define sync (make-socket 'rep))
(define pub (make-socket 'pub))

(bind-socket sync "tcp://*:5564")

(socket-option-set! pub 'hwm 2)        ;; optional high water mark
(bind-socket pub "tcp://*:5565")

(receive-message sync)

(do ((i 0 (+ i 1)))
    ((>= i 10))
  (send-message pub (sprintf "Update ~a" i))
  (thread-sleep! 1))

(send-message pub "END")

;;
(close-socket sync)
(close-socket pub)
(terminate-context (zmq-default-context))
