;; sending 10M static message w/o subscribers takes 46s
;; sending 10M static message w/o subscribers takes 12s after object-evict -> allocate
;; sending 10M static message w/o subscribers takes  9s after more tweaks
;; 10M dynamically-generated messages takes 46s or worse -- this is almost all GC

(use zmq extras)
(zmq-io-threads 1)

;; ((foreign-lambda void "srandom" unsigned-integer) (current-seconds))
;; (define crandom (foreign-lambda long "random"))
;; (define (random n)
;;   (fxmod (crandom) n))

(use random-bsd)

(define n->s number->string)

(define s (make-socket 'pub))
(bind-socket s "tcp://*:5556")
(bind-socket s "ipc://weather.ipc")

(define +static-msg+ "60056 20 10")

(define static-buf "               ")
(define (sprint-msg buf zip temp hum)
  ((foreign-lambda* void ((scheme-pointer buf) (int len) (int zip) (int temp) (int hum))
                    "snprintf(buf, len, \"%05d %03d %02d\", zip, temp, hum);")
   buf (string-length buf) zip temp hum)
  buf)

(time
 (let loop ((n 0))
   (let ((zipcode     (random 100000))
         (temperature (- (random 215) 80))
         (humidity    (+ (random 50) 10)))

     ;; (send-message s +static-msg+)
     ;; (send-message s (sprint-msg static-buf zipcode temperature humidity))

     (send-message s (string-append (string-pad (n->s zipcode) 5 #\0)
                                    " " (n->s temperature)
                                    " " (n->s humidity)
                                    ;; " " (n->s n)
                                    ))
    
     (when (= 0 (fxmod n 100000))
       (print "Sent " n " messages"))
     (if (= n 10000000)
         ;; 'done
         (loop (fx+ n 1))
         (loop (fx+ n 1))))))
