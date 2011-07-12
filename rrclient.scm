;;
;;  Hello World client
;;  Connects REQ socket to tcp://localhost:5559
;;  Sends "Hello" to server, expects "World" back
;;

(use zmq)

(define s (make-socket 'req))
(connect-socket s "tcp://localhost:5559")

(do ((i 0 (+ i 1)))
    ((>= i 10))
  (send-message s "Hello")
  (printf "Received reply ~a [~a]\n"
          i (receive-message s)))

