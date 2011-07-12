;;  Hello World server
;;  Connects REP socket to tcp://*:5560
;;  Expects "Hello" from client, replies with "World"

(use zmq srfi-18)

(define s (make-socket 'rep))
(connect-socket s "tcp://localhost:5560")

(let loop ()
  (printf "Received request: [~a]\n" (receive-message s))
  (thread-sleep! 1)
  (send-message s "World")
  (loop))
