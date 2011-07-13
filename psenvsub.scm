(use zmq)

(define sub (make-socket 'sub))
(socket-option-set! sub 'subscribe "B")
(connect-socket sub "tcp://localhost:5563")

(let loop ()
  (printf "[~a] " (receive-message sub))
  (print (receive-message sub))
  (loop))


