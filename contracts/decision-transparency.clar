;; Decision Transparency Contract
;; Records AI decision-making processes for audit trails

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))

;; Data structures
(define-map decision-records
  { decision-id: (string-ascii 64) }
  {
    system-id: (string-ascii 64),
    decision-type: (string-ascii 64),
    input-data-hash: (buff 32),
    output-data-hash: (buff 32),
    confidence-score: uint,
    timestamp: uint,
    decision-maker: principal,
    rationale: (string-ascii 512)
  }
)

(define-map decision-audits
  { audit-id: (string-ascii 64) }
  {
    decision-id: (string-ascii 64),
    auditor: principal,
    audit-result: (string-ascii 32),
    audit-notes: (string-ascii 512),
    audit-date: uint
  }
)

;; Public functions
(define-public (record-decision
  (decision-id (string-ascii 64))
  (system-id (string-ascii 64))
  (decision-type (string-ascii 64))
  (input-hash (buff 32))
  (output-hash (buff 32))
  (confidence uint)
  (rationale (string-ascii 512))
)
  (ok (map-set decision-records
    { decision-id: decision-id }
    {
      system-id: system-id,
      decision-type: decision-type,
      input-data-hash: input-hash,
      output-data-hash: output-hash,
      confidence-score: confidence,
      timestamp: block-height,
      decision-maker: tx-sender,
      rationale: rationale
    }
  ))
)

(define-public (audit-decision
  (audit-id (string-ascii 64))
  (decision-id (string-ascii 64))
  (result (string-ascii 32))
  (notes (string-ascii 512))
)
  (let ((decision (unwrap! (map-get? decision-records { decision-id: decision-id }) err-not-found)))
    (ok (map-set decision-audits
      { audit-id: audit-id }
      {
        decision-id: decision-id,
        auditor: tx-sender,
        audit-result: result,
        audit-notes: notes,
        audit-date: block-height
      }
    ))
  )
)

;; Read-only functions
(define-read-only (get-decision (decision-id (string-ascii 64)))
  (map-get? decision-records { decision-id: decision-id })
)

(define-read-only (get-audit (audit-id (string-ascii 64)))
  (map-get? decision-audits { audit-id: audit-id })
)

(define-read-only (verify-decision-integrity (decision-id (string-ascii 64)) (expected-input-hash (buff 32)) (expected-output-hash (buff 32)))
  (match (map-get? decision-records { decision-id: decision-id })
    decision (and
      (is-eq (get input-data-hash decision) expected-input-hash)
      (is-eq (get output-data-hash decision) expected-output-hash)
    )
    false
  )
)
