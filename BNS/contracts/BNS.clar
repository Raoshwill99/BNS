;; BNS Upgrade - Phase 2: Enhanced Functionality
;; contract: bns-enhanced.clar

(define-data-var admin principal tx-sender)

;; Enhanced data structure with multi-address support and metadata
(define-map registered-names 
  {name: (string-ascii 64)} 
  {
    owner: principal, 
    primary-btc-address: (buff 33),
    primary-stacks-address: principal,
    additional-btc-addresses: (list 5 (buff 33)),
    additional-stacks-addresses: (list 5 principal),
    expiration: uint,
    grace-period-end: uint,
    metadata-uri: (optional (string-utf8 256))
  })

;; Constants
(define-constant REGISTRATION_PERIOD_DAYS u365)
(define-constant GRACE_PERIOD_DAYS u30)
(define-constant REGISTRATION_COST_STX u10000) ;; 10,000 STX for annual registration
(define-constant NAME_TRANSFER_FEE_STX u1000) ;; 1,000 STX for name transfers

;; Register a new name with enhanced data structure
(define-public (register-name (name (string-ascii 64)) (btc-address (buff 33)) (metadata-uri (optional (string-utf8 256))))
  (let ((caller tx-sender)
        (current-time block-height)
        (expiration-time (+ current-time (* REGISTRATION_PERIOD_DAYS u144)))
        (grace-period (+ expiration-time (* GRACE_PERIOD_DAYS u144))))
    (asserts! (is-none (map-get? registered-names {name: name})) (err u1)) ;; Name already taken
    (asserts! (>= (stx-get-balance caller) REGISTRATION_COST_STX) (err u2)) ;; Insufficient funds
    
    (try! (stx-transfer? REGISTRATION_COST_STX caller (as-contract tx-sender)))
    
    (map-set registered-names 
      {name: name} 
      {owner: caller, 
       primary-btc-address: btc-address, 
       primary-stacks-address: caller,
       additional-btc-addresses: (list),
       additional-stacks-addresses: (list),
       expiration: expiration-time,
       grace-period-end: grace-period,
       metadata-uri: metadata-uri})
    (ok true)))

;; Add additional Bitcoin address
(define-public (add-btc-address (name (string-ascii 64)) (btc-address (buff 33)))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender)
        (current-addresses (get additional-btc-addresses name-info)))
    
    (asserts! (is-eq caller (get owner name-info)) (err u4)) ;; Not the owner
    (asserts! (< (len current-addresses) u5) (err u5)) ;; Too many addresses already
   (define-public (register-name (name (string-ascii 64)) (btc-address (buff 33)) (metadata-uri (optional (string-utf8 256))))
  (let ((caller tx-sender)
        (current-time block-height)
        (expiration-time (+ current-time (* REGISTRATION_PERIOD_DAYS u144)))
        (grace-period (+ expiration-time (* GRACE_PERIOD_DAYS u144))))
    (asserts! (is-none (map-get? registered-names {name: name})) (err u1)) ;; Name already taken
    (asserts! (>= (stx-get-balance caller) REGISTRATION_COST_STX) (err u2)) ;; Insufficient funds
    
    (try! (stx-transfer? REGISTRATION_COST_STX caller (as-contract tx-sender)))
    
    (map-set registered-names 
      {name: name} 
      {owner: caller, 
       primary-btc-address: btc-address, 
       primary-stacks-address: caller,
       additional-btc-addresses: (as-max-len? (list) u5), ;; Initialize as empty list with max length 5
       additional-stacks-addresses: (as-max-len? (list) u5), ;; Initialize as empty list with max length 5
       expiration: expiration-time,
       grace-period-end: grace-period,
       metadata-uri: metadata-uri})
    (ok true)))

;; Add additional Stacks address
(define-public (add-stacks-address (name (string-ascii 64)) (stacks-address principal))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender)
        (current-addresses (get additional-stacks-addresses name-info)))
    
    (asserts! (is-eq caller (get owner name-info)) (err u4)) ;; Not the owner
    (asserts! (< (len current-addresses) u5) (err u5)) ;; Too many addresses already
    
    (map-set registered-names 
      {name: name} 
      (merge name-info {additional-stacks-addresses: (append current-addresses stacks-address)}))
    (ok true)))

;; Update metadata URI
(define-public (update-metadata (name (string-ascii 64)) (new-metadata-uri (optional (string-utf8 256))))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender))
    
    (asserts! (is-eq caller (get owner name-info)) (err u4)) ;; Not the owner
    
    (map-set registered-names 
      {name: name} 
      (merge name-info {metadata-uri: new-metadata-uri}))
    (ok true)))

;; Transfer name to new owner
(define-public (transfer-name (name (string-ascii 64)) (new-owner principal))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender))
    
    (asserts! (is-eq caller (get owner name-info)) (err u4)) ;; Not the owner
    (asserts! (>= (stx-get-balance caller) NAME_TRANSFER_FEE_STX) (err u2)) ;; Insufficient funds
    
    (try! (stx-transfer? NAME_TRANSFER_FEE_STX caller (as-contract tx-sender)))
    
    (map-set registered-names 
      {name: name} 
      (merge name-info {owner: new-owner}))
    (ok true)))

;; Enhanced renewal with grace period handling
(define-public (renew-name (name (string-ascii 64)))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender)
        (current-time block-height)
        (new-expiration (+ current-time (* REGISTRATION_PERIOD_DAYS u144)))
        (new-grace-period (+ new-expiration (* GRACE_PERIOD_DAYS u144))))
    
    (asserts! (is-eq caller (get owner name-info)) (err u4)) ;; Not the owner
    (asserts! (>= (stx-get-balance caller) REGISTRATION_COST_STX) (err u2)) ;; Insufficient funds
    ;; Allow renewal if current time is before grace period ends
    (asserts! (< current-time (get grace-period-end name-info)) (err u6)) ;; Past grace period
    
    (try! (stx-transfer? REGISTRATION_COST_STX caller (as-contract tx-sender)))
    
    (map-set registered-names 
      {name: name} 
      (merge name-info {
        expiration: new-expiration,
        grace-period-end: new-grace-period
      }))
    (ok true)))

;; Read-only function to check name status
(define-read-only (get-name-status (name (string-ascii 64)))
  (let ((name-info (map-get? registered-names {name: name})))
    (if (is-none name-info)
        (ok "available")
        (let ((info (unwrap-panic name-info))
              (current-time block-height))
          (if (< current-time (get expiration info))
              (ok "active")
              (if (< current-time (get grace-period-end info))
                  (ok "grace-period")
                  (ok "expired")))))))))