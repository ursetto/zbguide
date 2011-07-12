(use zmq)

(define +ntasks+ 100)

(define s (make-socket 'pull))
(bind-socket s "tcp://*:5558")
(define ctrl (make-socket 'pub))
(bind-socket ctrl "tcp://*:5559")

(receive-message s)  ;; wait for start of batch (0 message)

(define start-time (current-milliseconds))

(do ((task 0 (+ task 1)))
    ((= task +ntasks+))
  (receive-message s) ;; discard empty message
  (display (if (= 0 (modulo task 10))
               ":" "."))
  (flush-output))

(newline)
(print "Total elapsed time: "
       (- (current-milliseconds) start-time)
       " ms")

(send-message ctrl "KILL")
