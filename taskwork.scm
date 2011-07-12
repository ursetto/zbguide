(use zmq)
(use (only srfi-18 thread-sleep!))

(define vent (make-socket 'pull))
(define sink (make-socket 'push))
(connect-socket vent "tcp://localhost:5557")
(connect-socket sink "tcp://localhost:5558")

(let loop ()
  (let ((msg (receive-message vent)))
    ;; Simple progress indicator for the viewer
    (flush-output)
    (print msg ".")

    (thread-sleep! (/ (string->number msg) 1000.0))
    (send-message sink "")
    (loop)))
