(use zmq srfi-18)

(define wx (make-socket 'sub))
(define vent (make-socket 'pull))

(socket-option-set! wx 'subscribe "60047 ")
(connect-socket wx   "tcp://localhost:5556")
(connect-socket vent "tcp://localhost:5557")

(define items (poll-items (list wx vent) '()))

(let loop ()
  (poll items #t)
  (for-each-poll-item
   items
   (lambda (s)
     (print "received msg: " (receive-message s)))
   identity)
  (thread-sleep! 0.25)
  (loop))
