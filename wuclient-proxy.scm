;; wuclient-proxy: connect to wuproxy and stream weather updates
(use zmq matchable data-structures)

(define +nupdates+ 100)
(define filter
  (string-append (if (null? (command-line-arguments))
                     "60056"
                     (car (command-line-arguments)))
                 " "))

(define s (make-socket 'sub))
(connect-socket s "tcp://localhost:8100")       ;; connect to wuproxy
(socket-option-set! s 'subscribe filter)

(let loop ((n 0) (temp 0))
  (if (= n +nupdates+)
      (printf "Average temperature for zip ~Awas ~aF"
              filter (/ temp n))
      (let ((msg (receive-message s)))
        (match (string-split msg " ")
               ((zipcode temperature relhumidity)
                (printf "Received msg ~S\n" msg)
                (loop (+ n 1) (+ temp (string->number temperature))))))))

(close-socket s)
