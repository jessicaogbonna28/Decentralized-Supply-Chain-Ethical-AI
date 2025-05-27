;; AI System Verification Contract
;; Validates artificial intelligence systems in the supply chain

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))

;; Data structures
(define-map ai-systems
  { system-id: (string-ascii 64) }
  {
    owner: principal,
    name: (string-ascii 128),
    version: (string-ascii 32),
    verification-status: (string-ascii 32),
    verification-date: uint,
    verifier: principal
  }
)

(define-map verification-criteria
  { criteria-id: (string-ascii 64) }
  {
    name: (string-ascii 128),
    description: (string-ascii 256),
    required: bool,
    active: bool
  }
)

;; Public functions
(define-public (register-ai-system (system-id (string-ascii 64)) (name (string-ascii 128)) (version (string-ascii 32)))
  (let ((existing-system (map-get? ai-systems { system-id: system-id })))
    (if (is-some existing-system)
      (err err-already-verified)
      (ok (map-set ai-systems
        { system-id: system-id }
        {
          owner: tx-sender,
          name: name,
          version: version,
          verification-status: "pending",
          verification-date: block-height,
          verifier: tx-sender
        }
      ))
    )
  )
)

(define-public (verify-ai-system (system-id (string-ascii 64)) (status (string-ascii 32)))
  (let ((system (unwrap! (map-get? ai-systems { system-id: system-id }) err-not-found)))
    (if (is-eq tx-sender contract-owner)
      (ok (map-set ai-systems
        { system-id: system-id }
        (merge system {
          verification-status: status,
          verification-date: block-height,
          verifier: tx-sender
        })
      ))
      err-owner-only
    )
  )
)

(define-public (add-verification-criteria (criteria-id (string-ascii 64)) (name (string-ascii 128)) (description (string-ascii 256)) (required bool))
  (if (is-eq tx-sender contract-owner)
    (ok (map-set verification-criteria
      { criteria-id: criteria-id }
      {
        name: name,
        description: description,
        required: required,
        active: true
      }
    ))
    err-owner-only
  )
)

;; Read-only functions
(define-read-only (get-ai-system (system-id (string-ascii 64)))
  (map-get? ai-systems { system-id: system-id })
)

(define-read-only (get-verification-criteria (criteria-id (string-ascii 64)))
  (map-get? verification-criteria { criteria-id: criteria-id })
)

(define-read-only (is-system-verified (system-id (string-ascii 64)))
  (match (map-get? ai-systems { system-id: system-id })
    system (is-eq (get verification-status system) "verified")
    false
  )
)
