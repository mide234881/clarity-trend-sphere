;; TrendSphere Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-category (err u104))
(define-constant err-invalid-item (err u105))

;; Reward Constants
(define-constant base-reward u100)
(define-constant vote-multiplier u5)
(define-constant max-reward u1000)

;; Categories
(define-constant categories 
  (list 
    "streetwear"
    "formal" 
    "casual"
    "vintage"
    "luxury"
  )
)

;; Data Variables
(define-data-var next-collection-id uint u0)
(define-data-var next-item-id uint u0)
(define-data-var reward-pool uint u0)

;; [Previous maps remain unchanged]

;; Create a new collection
(define-public (create-collection (title (string-ascii 50)) (description (string-ascii 500)) (category (string-ascii 20)) (items (list 10 uint)))
    (let
        (
            (collection-id (var-get next-collection-id))
            (curator-existing-stats (default-to {collections: u0, total-votes: u0, reputation: u0, rewards-earned: u0} 
                (map-get? curator-stats tx-sender)))
        )
        (asserts! (is-valid-category category) err-invalid-category)
        (try! (validate-items items))
        (map-set collections collection-id {
            creator: tx-sender,
            title: title,
            description: description,
            category: category,
            items: items,
            votes: u0,
            created-at: block-height,
            rewards-claimed: false
        })
        (map-set curator-stats tx-sender 
            (merge curator-existing-stats {
                collections: (+ u1 (get collections curator-existing-stats))
            }))
        (var-set next-collection-id (+ collection-id u1))
        (ok collection-id)
    )
)

;; List item for sale
(define-public (list-item (name (string-ascii 100)) (description (string-ascii 500)) (price uint) (category (string-ascii 20)))
    (let
        ((item-id (var-get next-item-id)))
        (asserts! (is-valid-category category) err-invalid-category)
        (map-set items item-id {
            name: name,
            description: description,
            price: price,
            category: category,
            seller: tx-sender,
            available: true
        })
        (var-set next-item-id (+ item-id u1))
        (ok item-id)
    )
)

;; Internal functions

(define-private (validate-items (items (list 10 uint)))
    (let
        ((valid-length (<=  (len items) u10))
         (items-exist (fold check-items items true)))
        (asserts! valid-length err-unauthorized)
        (asserts! items-exist err-invalid-item)
        (ok true)
    )
)

(define-private (check-items (item uint) (valid bool))
    (and valid (is-some (map-get? items item)))
)

(define-private (calculate-rewards (collection (tuple (creator principal) (votes uint) (rewards-claimed bool))))
    (let
        ((total-reward (min max-reward (* (+ base-reward (* (get votes collection) vote-multiplier)))))
        total-reward
    )
)

;; [Rest of the contract remains unchanged]
