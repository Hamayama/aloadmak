;; -*- coding: utf-8 -*-
;;
;; aloadmak.scm
;; 2017-9-27 v1.13
;;
;; ＜内容＞
;;   Gauche で autoload のコードを生成するためのモジュールです。
;;   use を autoload に変更してロードを遅延したい場合に使用できます。
;;
;;   詳細については、以下のページを参照ください。
;;   https://github.com/Hamayama/aloadmak
;;
;; ＜注意事項＞
;;   単純にシンボルを検索しているため、誤ったコードを生成することがあります。
;;
(define-module aloadmak
  (use gauche.test)
  (use gauche.version)
  (export
    aloadmak))
(select-module aloadmak)

;; autoload のコードを生成する
;;   module-or-file 対象のモジュールを表すシンボル、または、スクリプトファイル名
;;   use-module     対象の内部で使用するモジュールを表すシンボル
(define (aloadmak module-or-file use-module)

  ;; モジュールの取得
  (define (get-module module)
    (cond
     ((module? module)
      module)
     ((symbol? module)
      (or (find-module module)
          (if (library-exists? module)
            (begin
              (eval `(use ,module) (interaction-environment))
              (find-module module))
            #f)
          (error "no such module" module)))
     (else
      (error "module required, but got" module))))

  ;; ファイル名の取得
  (define (get-file-name module-or-file)
    (cond
     ((module? module-or-file)
      (module-name->path (module-name module-or-file)))
     ((symbol? module-or-file)
      (module-name->path module-or-file))
     ((string? module-or-file)
      module-or-file)
     (else
      (error "module or filename required, but got" module-or-file))))

  ;; シンボルを検索して、autoload のコードを生成する
  (let* ((file         (get-file-name module-or-file))
         (use-mod      (get-module use-module))
         (use-mod-syms (module-exports use-mod))
         (mod-syms     '()))

    ;; シンボル1個の検索
    (define (search sym)
      (if (memq sym use-mod-syms)
        (push! mod-syms sym)))

    ;; ファイルからS式を読み込み、再帰的に検索する
    (with-input-from-port (get-load-port file)
      (lambda ()
        (let loop ((s (read)))
          (cond
           ((eof-object? s))
           ((pair? s)
            ;; car 部と cdr 部に分けて処理する
            (let loop2 ((s1 (car s)) (s2 (cdr s)))
              ;; car 部の処理
              (if (pair? s1)
                (loop2 (car s1) (cdr s1))
                (search s1))
              ;; cdr 部の処理
              (if (pair? s2)
                (loop2 (car s2) (cdr s2))
                (begin
                  (search s2)
                  (loop (read))))))
           (else
            (search s)
            (loop (read)))))))

    ;; autoload のコードを生成して返す
    `(autoload
      ,(module-name use-mod)
      ,@(delete-duplicates
         ;; for Gauche v0.9.4 compatibility
         ;; for Gauche v0.9.3.3 compatibility
         ;(sort mod-syms)
         ;(sort mod-syms string<? x->string)
         (sort mod-syms (lambda (a b) (string<? (x->string a) (x->string b))))
         ))))


;; load 用のポートの取得
;; (参考 : Gauche の src/libeval.scm の load および find-load-file )
(define find-load-file
  ;; for Gauche v0.9.4 compatibility
  ;; for Gauche v0.9.3.3 compatibility
  (if (version<=? (gauche-version) "0.9.4")
    (lambda (file paths suffixes :key (error-if-not-found #f)
                  (allow-archive #f) (relative-dot-path #f))
      ((with-module gauche.internal find-load-file)
       file paths suffixes error-if-not-found relative-dot-path))
    (with-module gauche.internal find-load-file)))
(define (get-load-port file)
  (if-let1 r (find-load-file file *load-path* *load-suffixes*
                             :error-if-not-found #t
                             :allow-archive #t)
    (let* ((path (car r))
           (remaining-paths (cadr r))
           (hooked? (pair? (cddr r)))
           (opener (if hooked? (caddr r) open-input-file))
           (port (guard (e (else e)) (opener path))))
      (if (not (input-port? port))
        (raise port)
        (open-coding-aware-port port)))))


