;; BNS Upgrade - Phase 1: Core Infrastructure
;; contract: bns-core.clar

(define-data-var admin principal tx-sender)
(define-map registered-names 
  {name: (string-ascii 64)} 
  {owner: principal, bitcoin-address: (buff 33), stacks-address: principal, expiration: uint})

(define-constant REGISTRATION_PERIOD_DAYS u365)
(define-constant REGISTRATION_COST_STX u10000) ;; 10,000 STX for annual registration

;; Register a new name
(define-public (register-name (name (string-ascii 64)) (btc-address (buff 33)))
  (let ((caller tx-sender)
        (current-time block-height)
        (expiration-time (+ current-time (* REGISTRATION_PERIOD_DAYS u144))))
    (asserts! (is-none (map-get? registered-names {name: name})) (err u1)) ;; Name already taken
    (asserts! (>= (stx-get-balance caller) REGISTRATION_COST_STX) (err u2)) ;; Insufficient funds
    
    (try! (stx-transfer? REGISTRATION_COST_STX caller (as-contract tx-sender)))
    
    (map-set registered-names 
      {name: name} 
      {owner: caller, 
       bitcoin-address: btc-address, 
       stacks-address: caller, 
       expiration: expiration-time})
    (ok true)))

;; Lookup name information
(define-read-only (name-lookup (name (string-ascii 64)))
  (map-get? registered-names {name: name}))

;; Check if name is available
(define-read-only (is-name-available (name (string-ascii 64)))
  (is-none (map-get? registered-names {name: name})))

;; Renew an existing name
(define-public (renew-name (name (string-ascii 64)))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender)
        (current-time block-height)
        (new-expiration (+ current-time (* REGISTRATION_PERIOD_DAYS u144))))
    
    (asserts! (is-eq caller (get owner name-info)) (err u4)) ;; Not the owner
    (asserts! (>= (stx-get-balance caller) REGISTRATION_COST_STX) (err u2)) ;; Insufficient funds
    
    (try! (stx-transfer? REGISTRATION_COST_STX caller (as-contract tx-sender)))
    
    (map-set registered-names 
      {name: name} 
      (merge name-info {expiration: new-expiration}))
    (ok true)))