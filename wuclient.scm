;; C publisher / C subscriber      takes 5-9 real seconds for 100 updates
;; C publisher / Scheme subscriber also takes 5-9 real seconds for 100 updates
;; Scheme pub  / Scheme sub        took 2m23s, 2m6s, 1m34s, 2m21s
;;                                  now 1m10s
;; C pub / C sub                   took 1m45s, 1m58s


(use zmq matchable data-structures)

(define +nupdates+ 100)
(define filter
  (string-append (if (null? (command-line-arguments))
                     "60056"
                     (car (command-line-arguments)))
                 " "))

(define s (make-socket 'sub))
(connect-socket s "tcp://localhost:5556")
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
