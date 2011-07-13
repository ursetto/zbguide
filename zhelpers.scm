;; helper module for example applications, like zhelpers.h

(use (only srfi-13 string-pad string-every))

(define (u8vector-every u8 pred?)
  (let loop ((i 0))
    (if (= i (u8vector-length u8))
        #t
        (and (pred? (u8vector-ref u8 i))
             (loop (+ i 1))))))

(define (zero-pad x width)
  (string-pad (number->string x) width #\0))

(define (dump-socket s)
  (print "----------------------------------------")
  (let loop ()
    (let* ((msg (receive-message* s as: 'blob))
           (more? (socket-option s 'rcvmore))
           (u8 (blob->u8vector/shared msg))
           (len (u8vector-length u8)))
      (print "[" (zero-pad len 3) "] "
             (if (u8vector-every u8 (cut < 31 <> 128))
                 (blob->string msg)
                 msg))         ;; assume blob prints as #${hex}
      (when more? (loop)))))
