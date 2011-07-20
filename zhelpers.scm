;; helper module for example applications, like zhelpers.h

(use (only srfi-13 string-pad string-every)
     srfi-4
     random-bsd   ;; for randomize-socket-identity!
     )

(define (u8vector-every u8 pred?)
  (let loop ((i 0))
    (if (= i (u8vector-length u8))
        #t
        (and (pred? (u8vector-ref u8 i))
             (loop (+ i 1))))))

(define (zero-pad width x #!optional (radix 10))
  (string-pad (number->string x radix) width #\0))

(define (dump-socket s)
  (print "----------------------------------------")
  (let loop ()
    (let* ((msg (receive-message* s as: 'blob))
           (more? (socket-option s 'rcvmore))
           (u8 (blob->u8vector/shared msg))
           (len (u8vector-length u8)))
      (print "[" (zero-pad 3 len) "] "
             (if (u8vector-every u8 (cut < 31 <> 128))
                 (blob->string msg)
                 msg))         ;; assume blob prints as #${hex}
      (when more? (loop)))))

(define (randomize-socket-identity! s)
  (socket-option-set! s 'identity
                      (string-append
                       (zero-pad 4 (random #xffff) 16)
                       "-"
                       (zero-pad 4 (random #xffff) 16))))

(define-syntax dotimes
  (syntax-rules ()
    ((dotimes (var times final) e0 e1 ...)
     (let loop ((var 0))
       (if (>= var times)
           final
           (begin e0 e1 ...
                  (loop (+ var 1))))))
    ((dotimes (var times) e0 e1 ...)
     (dotimes (var times (void)) e0 e1 ...))))

(define-syntax forever
  (syntax-rules () ((forever e0 e1 ...)
                    (let loop () e0 e1 ... (loop)))))

(define (thread-millisleep! ms)
  (thread-sleep! (/ ms 1000)))

(define (send-multipart-message s parts)
  (let loop ((parts parts))
    (cond ((null? parts)
           (error 'send-multipart-message "Empty message"))
          ((null? (cdr parts))
           (send-message s (car parts)))
          (else
           (send-message s (car parts) send-more: #t)
           (loop (cdr parts))))))
(define (send-multipart-message* s . parts)
  (send-multipart-message s parts))

(define (receive-multipart-message s)
  (let loop ((msg '()))
    (let* ((frame (receive-message* s))
           (more? (socket-option s 'rcvmore)))
      (if more?
          (loop (cons frame msg))
          (reverse (cons frame msg))))))

;; Insert address and "" in front of msg list (i.e., route message to address).
(define (wrap address msg)
  (cons address (cons "" msg)))
