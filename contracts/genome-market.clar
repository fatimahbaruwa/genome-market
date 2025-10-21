;; title: genome-market
;; version: 1.0.0
;; summary: A marketplace for tokenizing and licensing DNA snippets for research
;; description: Users can tokenize specific DNA snippets, list them for licensing,
;; and researchers can purchase licenses to use the genomic data.

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-snippet-not-found (err u102))
(define-constant err-snippet-already-exists (err u103))
(define-constant err-not-for-sale (err u104))
(define-constant err-insufficient-payment (err u105))
(define-constant err-already-licensed (err u106))
(define-constant err-invalid-price (err u107))

;; data vars
(define-data-var snippet-id-nonce uint u0)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; data maps
;; Store DNA snippet metadata
(define-map dna-snippets
  { snippet-id: uint }
  {
    owner: principal,
    dna-hash: (buff 32),
    description: (string-ascii 256),
    sequence-length: uint,
    price: uint,
    for-sale: bool,
    created-at: uint
  }
)

;; Track licenses purchased by researchers
(define-map licenses
  { snippet-id: uint, licensee: principal }
  {
    purchased-at: uint,
    price-paid: uint
  }
)

;; Track total earnings per snippet owner
(define-map owner-earnings
  { owner: principal }
  { total-earned: uint }
)

;; public functions

;; Tokenize a new DNA snippet
(define-public (tokenize-snippet (dna-hash (buff 32)) (description (string-ascii 256)) (sequence-length uint) (price uint))
  (let
    (
      (snippet-id (var-get snippet-id-nonce))
    )
    ;; Validate inputs
    (asserts! (> sequence-length u0) err-invalid-price)
    (asserts! (> price u0) err-invalid-price)

    ;; Create the snippet
    (map-set dna-snippets
      { snippet-id: snippet-id }
      {
        owner: tx-sender,
        dna-hash: dna-hash,
        description: description,
        sequence-length: sequence-length,
        price: price,
        for-sale: true,
        created-at: block-height
      }
    )

    ;; Increment nonce
    (var-set snippet-id-nonce (+ snippet-id u1))

    (ok snippet-id)
  )
)

;; Update snippet price
(define-public (update-price (snippet-id uint) (new-price uint))
  (let
    (
      (snippet (unwrap! (map-get? dna-snippets { snippet-id: snippet-id }) err-snippet-not-found))
    )
    (asserts! (is-eq tx-sender (get owner snippet)) err-not-token-owner)
    (asserts! (> new-price u0) err-invalid-price)

    (map-set dna-snippets
      { snippet-id: snippet-id }
      (merge snippet { price: new-price })
    )

    (ok true)
  )
)

;; Toggle snippet for sale status
(define-public (toggle-for-sale (snippet-id uint))
  (let
    (
      (snippet (unwrap! (map-get? dna-snippets { snippet-id: snippet-id }) err-snippet-not-found))
    )
    (asserts! (is-eq tx-sender (get owner snippet)) err-not-token-owner)

    (map-set dna-snippets
      { snippet-id: snippet-id }
      (merge snippet { for-sale: (not (get for-sale snippet)) })
    )

    (ok true)
  )
)

;; Purchase a license for a DNA snippet
(define-public (purchase-license (snippet-id uint))
  (let
    (
      (snippet (unwrap! (map-get? dna-snippets { snippet-id: snippet-id }) err-snippet-not-found))
      (price (get price snippet))
      (owner (get owner snippet))
      (platform-fee (/ (* price (var-get platform-fee-percentage)) u100))
      (owner-payment (- price platform-fee))
      (existing-license (map-get? licenses { snippet-id: snippet-id, licensee: tx-sender }))
    )
    ;; Validate purchase
    (asserts! (get for-sale snippet) err-not-for-sale)
    (asserts! (is-none existing-license) err-already-licensed)

    ;; Transfer payment to snippet owner
    (try! (stx-transfer? owner-payment tx-sender owner))

    ;; Transfer platform fee to contract owner
    (try! (stx-transfer? platform-fee tx-sender contract-owner))

    ;; Record the license
    (map-set licenses
      { snippet-id: snippet-id, licensee: tx-sender }
      {
        purchased-at: block-height,
        price-paid: price
      }
    )

    ;; Update owner earnings
    (match (map-get? owner-earnings { owner: owner })
      current-earnings
        (map-set owner-earnings
          { owner: owner }
          { total-earned: (+ (get total-earned current-earnings) owner-payment) }
        )
      (map-set owner-earnings
        { owner: owner }
        { total-earned: owner-payment }
      )
    )

    (ok true)
  )
)

;; Update platform fee (owner only)
(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-fee u20) err-invalid-price) ;; Max 20% fee
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

;; read only functions

;; Get snippet details
(define-read-only (get-snippet (snippet-id uint))
  (map-get? dna-snippets { snippet-id: snippet-id })
)

;; Check if user has license for snippet
(define-read-only (has-license (snippet-id uint) (user principal))
  (is-some (map-get? licenses { snippet-id: snippet-id, licensee: user }))
)

;; Get license details
(define-read-only (get-license (snippet-id uint) (licensee principal))
  (map-get? licenses { snippet-id: snippet-id, licensee: licensee })
)

;; Get total earnings for an owner
(define-read-only (get-owner-earnings (owner principal))
  (default-to { total-earned: u0 } (map-get? owner-earnings { owner: owner }))
)

;; Get current snippet ID nonce
(define-read-only (get-snippet-count)
  (ok (var-get snippet-id-nonce))
)

;; Get platform fee percentage
(define-read-only (get-platform-fee)
  (ok (var-get platform-fee-percentage))
)
