;; BNS Upgrade - Phase 3: Advanced Features
;; contract: bns-advanced.clar

(define-data-var admin principal tx-sender)

;; NFT trait implementation for BNS names
(impl-trait .sip-009-trait.sip-009-trait)

;; Enhanced data structure with SIP-009 NFT support and advanced features
(define-map registered-names 
  {name: (string-ascii 64)} 
  {
    owner: principal, 
    primary-btc-address: (buff 33),
    primary-stacks-address: principal,
    additional-btc-addresses: (list 10 (buff 33)),
    additional-stacks-addresses: (list 10 principal),
    expiration: uint,
    grace-period-end: uint,
    metadata-uri: (optional (string-utf8 512)),
    social-handles: (list 5 {platform: (string-ascii 32), handle: (string-utf8 128)}),
    reputation-score: (optional uint),
    token-id: uint,
    subdomain-count: uint
  })

;; Constants for various service tiers
(define-constant REGISTRATION_PERIOD_DAYS u365)
(define-constant GRACE_PERIOD_DAYS u30)
(define-constant BASE_REGISTRATION_COST u10000) ;; 10,000 STX for standard names
(define-constant PREMIUM_NAME_COST u100000) ;; 100,000 STX for premium names (shorter than 5 chars)
(define-constant SUBDOMAIN_REGISTRATION_COST u1000) ;; 1,000 STX for subdomains
(define-constant NAME_TRANSFER_FEE_STX u1000) ;; 1,000 STX for name transfers
(define-constant MAX_SUBDOMAINS_PER_NAME u100)

;; Token ID tracking and name auction support
(define-data-var last-token-id uint u0)
(define-map token-id-to-name uint (string-ascii 64))
(define-map auctions 
  {name: (string-ascii 64)} 
  {
    highest-bidder: principal,
    highest-bid: uint,
    end-block: uint
  })

;; SIP-009 implementation
(define-data-var token-uri (string-utf8 256) "https://bns.btc/metadata/")

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id)))

(define-private (is-valid-name (name (string-ascii 64)))
  (and
    (>= (len name) u3) ;; Minimum name length of 3 characters
    (is-valid-name-chars name)
  )
)
(define-private (is-valid-name (name (string-ascii 64)))
  (and
    (>= (len name) u3) ;; Minimum name length of 3 characters
    (is-valid-name-chars name)
  )
)

(define-private (is-valid-name-chars (name (string-ascii 64)))
  (>= (len name) u3) ;; Minimum name length of 3 characters
)
(define-read-only (get-owner (token-id uint))
  (let ((name (map-get? token-id-to-name token-id)))
    (if (is-none name)
        (err u404)
        (let ((name-info (map-get? registered-names {name: (unwrap-panic name)})))
          (if (is-none name-info)
              (err u404)
              (ok (get owner (unwrap-panic name-info))))))))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (let ((name (unwrap! (map-get? token-id-to-name token-id) (err u404))))
    (transfer-name name recipient)))

;; Register a name with token issuance
(define-public (register-name (name (string-ascii 64)) (btc-address (buff 33)) (metadata-uri (optional (string-utf8 512))))
  (let ((caller tx-sender)
        (current-time block-height)
        (expiration-time (+ current-time (* REGISTRATION_PERIOD_DAYS u144)))
        (grace-period (+ expiration-time (* GRACE_PERIOD_DAYS u144)))
        (name-length (len name))
        (registration-cost (if (< name-length u5) PREMIUM_NAME_COST BASE_REGISTRATION_COST))
        (token-id (+ (var-get last-token-id) u1)))
    
    ;; Check availability and funds
    (asserts! (is-none (map-get? registered-names {name: name})) (err u1)) ;; Name already taken
    (asserts! (>= (stx-get-balance caller) registration-cost) (err u2)) ;; Insufficient funds
    
    ;; Payment
    (try! (stx-transfer? registration-cost caller (as-contract tx-sender)))
    
    ;; Register name and issue token
    (map-set registered-names 
      {name: name} 
      {owner: caller, 
       primary-btc-address: btc-address, 
       primary-stacks-address: caller,
       additional-btc-addresses: (list),
       additional-stacks-addresses: (list),
       expiration: expiration-time,
       grace-period-end: grace-period,
       metadata-uri: metadata-uri,
       social-handles: (list),
       reputation-score: none,
       token-id: token-id,
       subdomain-count: u0})
    
    ;; Update token mapping
    (map-set token-id-to-name token-id name)
    (var-set last-token-id token-id)
    
    (ok token-id)))

;; Register a subdomain under an existing name
(define-public (register-subdomain (parent-name (string-ascii 64)) (subdomain (string-ascii 32)) (btc-address (buff 33)))
  (let ((caller tx-sender)
        (full-name (concat (concat subdomain ".") parent-name))
        (parent-info (unwrap! (map-get? registered-names {name: parent-name}) (err u3))) ;; Parent name not found
        (current-time block-height)
        (expiration-time (get expiration parent-info)) ;; Inherit parent expiration
        (grace-period (get grace-period-end parent-info)) ;; Inherit parent grace period
        (parent-owner (get owner parent-info))
        (subdomain-count (get subdomain-count parent-info))
        (token-id (+ (var-get last-token-id) u1)))
    
    ;; Validations
    (asserts! (is-none (map-get? registered-names {name: full-name})) (err u1)) ;; Subdomain already taken
    (asserts! (< current-time (get expiration parent-info)) (err u7)) ;; Parent domain expired
    (asserts! (< subdomain-count MAX_SUBDOMAINS_PER_NAME) (err u8)) ;; Too many subdomains
    (asserts! (>= (stx-get-balance caller) SUBDOMAIN_REGISTRATION_COST) (err u2)) ;; Insufficient funds
    
    ;; Payment (split between contract and parent domain owner)
    (try! (stx-transfer? SUBDOMAIN_REGISTRATION_COST caller (as-contract tx-sender)))
    (try! (as-contract (stx-transfer? (/ SUBDOMAIN_REGISTRATION_COST u2) tx-sender parent-owner)))
    
    ;; Register subdomain
    (map-set registered-names 
      {name: full-name} 
      {owner: caller, 
       primary-btc-address: btc-address, 
       primary-stacks-address: caller,
       additional-btc-addresses: (list),
       additional-stacks-addresses: (list),
       expiration: expiration-time,
       grace-period-end: grace-period,
       metadata-uri: none,
       social-handles: (list),
       reputation-score: none,
       token-id: token-id,
       subdomain-count: u0})
    
    ;; Update token mapping
    (map-set token-id-to-name token-id full-name)
    (var-set last-token-id token-id)
    
    ;; Update parent domain's subdomain count
    (map-set registered-names 
      {name: parent-name} 
      (merge parent-info {subdomain-count: (+ subdomain-count u1)}))
    
    (ok token-id)))

;; Start an auction for a premium name
(define-public (start-auction (name (string-ascii 64)) (starting-bid uint) (duration-blocks uint))
  (let ((caller tx-sender)
        (current-time block-height)
        (end-time (+ current-time duration-blocks)))
    
    (asserts! (is-none (map-get? registered-names {name: name})) (err u1)) ;; Name already taken
    (asserts! (is-none (map-get? auctions {name: name})) (err u9)) ;; Auction already exists
    (asserts! (>= starting-bid PREMIUM_NAME_COST) (err u10)) ;; Bid too low
    (asserts! (>= (stx-get-balance caller) starting-bid) (err u2)) ;; Insufficient funds
    
    ;; Lock starting bid
    (try! (stx-transfer? starting-bid caller (as-contract tx-sender)))
    
    ;; Create auction
    (map-set auctions
      {name: name}
      {highest-bidder: caller,
       highest-bid: starting-bid,
       end-block: end-time})
    
    (ok true)))

;; Place a bid in an ongoing auction
(define-public (place-bid (name (string-ascii 64)) (bid-amount uint))
  (let ((auction (unwrap! (map-get? auctions {name: name}) (err u11))) ;; Auction not found
        (caller tx-sender)
        (current-time block-height)
        (current-highest-bid (get highest-bid auction))
        (current-highest-bidder (get highest-bidder auction)))
    
    (asserts! (< current-time (get end-block auction)) (err u12)) ;; Auction ended
    (asserts! (> bid-amount current-highest-bid) (err u13)) ;; Bid too low
    (asserts! (>= (stx-get-balance caller) bid-amount) (err u2)) ;; Insufficient funds
    
    ;; Return previous highest bid
    (try! (as-contract (stx-transfer? current-highest-bid tx-sender current-highest-bidder)))
    
    ;; Lock new bid
    (try! (stx-transfer? bid-amount caller (as-contract tx-sender)))
    
    ;; Update auction
    (map-set auctions
      {name: name}
      {highest-bidder: caller,
       highest-bid: bid-amount,
       end-block: (get end-block auction)})
    
    (ok true)))

;; Finalize auction and register name to winner
(define-public (finalize-auction (name (string-ascii 64)) (btc-address (buff 33)))
  (let ((auction (unwrap! (map-get? auctions {name: name}) (err u11))) ;; Auction not found
        (caller tx-sender)
        (current-time block-height)
        (highest-bidder (get highest-bidder auction))
        (highest-bid (get highest-bid auction))
        (expiration-time (+ current-time (* REGISTRATION_PERIOD_DAYS u144)))
        (grace-period (+ expiration-time (* GRACE_PERIOD_DAYS u144)))
        (token-id (+ (var-get last-token-id) u1)))
    
    (asserts! (>= current-time (get end-block auction)) (err u14)) ;; Auction not ended
    (asserts! (is-eq caller highest-bidder) (err u15)) ;; Not the auction winner
    
    ;; Register name to winner
    (map-set registered-names 
      {name: name} 
      {owner: highest-bidder, 
       primary-btc-address: btc-address, 
       primary-stacks-address: highest-bidder,
       additional-btc-addresses: (list),
       additional-stacks-addresses: (list),
       expiration: expiration-time,
       grace-period-end: grace-period,
       metadata-uri: none,
       social-handles: (list),
       reputation-score: none,
       token-id: token-id,
       subdomain-count: u0})
    
    ;; Update token mapping
    (map-set token-id-to-name token-id name)
    (var-set last-token-id token-id)
    
    ;; Clean up auction data
    (map-delete auctions {name: name})
    
    (ok token-id)))

;; Add social media handle
(define-public (add-social-handle (name (string-ascii 64)) (platform (string-ascii 32)) (handle (string-utf8 128)))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender)
        (current-handles (get social-handles name-info)))
    
    (asserts! (is-eq caller (get owner name-info)) (err u4)) ;; Not the owner
    (asserts! (< (len current-handles) u5) (err u5)) ;; Too many handles already
    
    (map-set registered-names 
      {name: name} 
      (merge name-info {social-handles: (append current-handles {platform: platform, handle: handle})}))
    (ok true)))

;; Update reputation score (only by authorized entities)
(define-public (update-reputation (name (string-ascii 64)) (new-score uint))
  (let ((name-info (unwrap! (map-get? registered-names {name: name}) (err u3))) ;; Name not found
        (caller tx-sender))
    
    ;; Only admin or authorized parties can update reputation
    (asserts! (or (is-eq caller (var-get admin)) (is-eq caller (get owner name-info))) (err u16))
    (asserts! (<= new-score u100) (err u17)) ;; Score must be 0-100
    
    (map-set registered-names 
      {name: name} 
      (merge name-info {reputation-score: (some new-score)}))
    (ok true)))

;; Resolve name to address (with subdomain support)
(define-read-only (resolve-name (name (string-ascii 64)))
  (let ((name-info (map-get? registered-names {name: name})))
    (if (is-none name-info)
        (err u3)
        (let ((info (unwrap-panic name-info))
              (current-time block-height))
          (if (>= current-time (get grace-period-end info))
              (err u6) ;; Name expired
              (ok {
                btc-address: (get primary-btc-address info),
                stacks-address: (get primary-stacks-address info)
              }))))))

;; Reverse lookup: find name by address
(define-read-only (reverse-lookup (btc-address (buff 33)))
  (let ((names (map-entries registered-names)))
    ;; This would be inefficient in practice, but demonstrates the concept
    ;; In a real implementation, we would use a reverse index
    (filter names (lambda (entry)
      (is-eq (get primary-btc-address (get value entry)) btc-address)))))