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