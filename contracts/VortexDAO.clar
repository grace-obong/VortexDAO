;; Title: VortexDAO - Autonomous Treasury Management Protocol
;;
;; Summary:
;; A sophisticated decentralized autonomous organization (DAO) that enables 
;; community-driven treasury management with advanced governance mechanisms,
;; time-locked deposits, and democratic proposal execution on Stacks blockchain.
;;
;; Description:
;; VortexDAO represents the next evolution in decentralized finance governance,
;; combining traditional treasury management with cutting-edge blockchain technology.
;; Members can stake STX tokens to gain voting power, propose funding initiatives,
;; and collectively decide the allocation of community resources. The protocol
;; features built-in security measures including time-locks, minimum thresholds,
;; and anti-spam mechanisms to ensure responsible governance while maintaining
;; full decentralization and transparency.

;; PROTOCOL CONSTANTS
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-initialized (err u101))
(define-constant err-already-initialized (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-proposal-not-found (err u106))
(define-constant err-proposal-expired (err u107))
(define-constant err-already-voted (err u108))
(define-constant err-below-minimum (err u109))
(define-constant err-locked-period (err u110))
(define-constant err-transfer-failed (err u111))
(define-constant err-invalid-duration (err u112))
(define-constant err-zero-amount (err u113))
(define-constant err-invalid-target (err u114))
(define-constant err-invalid-description (err u115))
(define-constant err-invalid-proposal-id (err u116))
(define-constant err-invalid-vote (err u117))

;; Governance Parameters
(define-constant minimum-duration u144) ;; 1 day minimum voting period
(define-constant maximum-duration u20160) ;; 14 days maximum voting period

;; STATE VARIABLES
(define-data-var total-supply uint u0)
(define-data-var minimum-deposit uint u1000000) ;; 1 STX minimum stake
(define-data-var lock-period uint u1440) ;; ~10 days security lock
(define-data-var initialized bool false)
(define-data-var last-rebalance uint u0)
(define-data-var proposal-count uint u0)

;; DATA STRUCTURES

;; Member voting power and governance tokens
(define-map balances
  principal
  uint
)

;; Staking records with time-lock security
(define-map deposits
  principal
  {
    amount: uint,
    lock-until: uint,
    last-reward-block: uint,
  }
)

;; Governance proposals with comprehensive metadata
(define-map proposals
  uint
  {
    proposer: principal,
    description: (string-ascii 256),
    amount: uint,
    target: principal,
    expires-at: uint,
    executed: bool,
    yes-votes: uint,
    no-votes: uint,
  }
)

;; Vote tracking to prevent double-voting
(define-map votes
  {
    proposal-id: uint,
    voter: principal,
  }
  bool
)

;; INTERNAL FUNCTIONS

(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

(define-private (check-initialized)
  (ok (asserts! (var-get initialized) err-not-initialized))
)

(define-private (validate-proposal-id (proposal-id uint))
  (ok (asserts! (<= proposal-id (var-get proposal-count)) err-invalid-proposal-id))
)

(define-private (calculate-voting-power (voter principal))
  (default-to u0 (map-get? balances voter))
)

(define-private (transfer-tokens
    (sender principal)
    (recipient principal)
    (amount uint)
  )
  (let (
      (sender-balance (default-to u0 (map-get? balances sender)))
      (recipient-balance (default-to u0 (map-get? balances recipient)))
    )
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (map-set balances sender (- sender-balance amount))
    (map-set balances recipient (+ recipient-balance amount))
    (ok true)
  )
)

(define-private (mint-tokens
    (account principal)
    (amount uint)
  )
  (let ((current-balance (default-to u0 (map-get? balances account))))
    (map-set balances account (+ current-balance amount))
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok true)
  )
)

(define-private (burn-tokens
    (account principal)
    (amount uint)
  )
  (let ((current-balance (default-to u0 (map-get? balances account))))
    (asserts! (>= current-balance amount) err-insufficient-balance)
    (map-set balances account (- current-balance amount))
    (var-set total-supply (- (var-get total-supply) amount))
    (ok true)
  )
)

;; PUBLIC FUNCTIONS

;; Initialize the DAO protocol
(define-public (initialize)
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (asserts! (not (var-get initialized)) err-already-initialized)
    (var-set initialized true)
    (ok true)
  )
)

;; Stake STX to join the DAO and gain voting power
(define-public (deposit (amount uint))
  (begin
    (try! (check-initialized))
    (asserts! (>= amount (var-get minimum-deposit)) err-below-minimum)
    (asserts! (> amount u0) err-zero-amount)

    ;; Secure STX transfer to treasury
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; Record member staking details
    (map-set deposits tx-sender {
      amount: amount,
      lock-until: (+ stacks-block-height (var-get lock-period)),
      last-reward-block: stacks-block-height,
    })

    ;; Issue governance tokens
    (mint-tokens tx-sender amount)
  )
)

;; Withdraw staked STX after lock period expires
(define-public (withdraw (amount uint))
  (begin
    (try! (check-initialized))
    (asserts! (> amount u0) err-zero-amount)

    (let (
        (deposit-info (unwrap! (map-get? deposits tx-sender) err-unauthorized))
        (user-balance (unwrap! (get-balance tx-sender) err-unauthorized))
      )
      (asserts! (>= stacks-block-height (get lock-until deposit-info))
        err-locked-period
      )
      (asserts! (>= user-balance amount) err-insufficient-balance)

      ;; Burn governance tokens
      (try! (burn-tokens tx-sender amount))

      ;; Return STX to member
      (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender))
    )
  )
)

;; Submit new governance proposal for community funding
(define-public (create-proposal
    (description (string-ascii 256))
    (amount uint)
    (target principal)
    (duration uint)
  )
  (begin
    (try! (check-initialized))

    ;; Comprehensive input validation
    (asserts! (> (len description) u0) err-invalid-description)
    (asserts! (> amount u0) err-zero-amount)
    (asserts! (not (is-eq target (as-contract tx-sender))) err-invalid-target)
    (asserts! (and (>= duration minimum-duration) (<= duration maximum-duration))
      err-invalid-duration
    )

    (let (
        (proposer-balance (unwrap! (map-get? balances tx-sender) err-unauthorized))
        (proposal-id (+ (var-get proposal-count) u1))
      )
      (asserts! (> proposer-balance u0) err-unauthorized)

      ;; Register new proposal in governance system
      (map-set proposals proposal-id {
        proposer: tx-sender,
        description: description,
        amount: amount,
        target: target,
        expires-at: (+ stacks-block-height duration),
        executed: false,
        yes-votes: u0,
        no-votes: u0,
      })

      (var-set proposal-count proposal-id)
      (ok proposal-id)
    )
  )
)

;; Cast weighted vote on active governance proposal
(define-public (vote
    (proposal-id uint)
    (vote-for bool)
  )
  (begin
    (try! (check-initialized))
    (try! (validate-proposal-id proposal-id))

    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
        (voter-power (calculate-voting-power tx-sender))
      )
      (asserts! (> voter-power u0) err-unauthorized)
      (asserts! (< stacks-block-height (get expires-at proposal))
        err-proposal-expired
      )
      (asserts!
        (is-none (map-get? votes {
          proposal-id: proposal-id,
          voter: tx-sender,
        }))
        err-already-voted
      )

      ;; Register member's vote decision
      (map-set votes {
        proposal-id: proposal-id,
        voter: tx-sender,
      }
        vote-for
      )

      ;; Update proposal vote tallies
      (map-set proposals proposal-id
        (merge proposal {
          yes-votes: (if vote-for
            (+ (get yes-votes proposal) voter-power)
            (get yes-votes proposal)
          ),
          no-votes: (if vote-for
            (get no-votes proposal)
            (+ (get no-votes proposal) voter-power)
          ),
        })
      )

      (ok true)
    )
  )
)