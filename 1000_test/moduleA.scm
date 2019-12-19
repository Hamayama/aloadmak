(define-module moduleA
  (use moduleB)
  (export varA1 varA2 procA1 procA2))
(select-module moduleA)

(define varA1 100)
(define varA2 '((1 (2 varB1)) (#(varB2 3 4) 5 6)))
(define (procA1) (procB1))
(define (procA2 x) (procB2 x))

