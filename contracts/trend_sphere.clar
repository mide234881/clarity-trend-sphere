;; TrendSphere Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-category (err u104))

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
(define-data-var reward-pool uint u0)

;; Data Maps
(define-map collections 
    uint 
    {
        creator: principal,
        title: (string-ascii 50),
        description: (string-ascii 500),
        category: (string-ascii 20),
        items: (list 10 uint),
        votes: uint,
        created-at: uint,
        rewards-claimed: bool
    }
)

(define-map curator-stats
    principal
    {
        collections: uint,
        total-votes: uint,
        reputation: uint,
        rewards-earned: uint
    }
)

(define-map items
    uint
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        price: uint,
        seller: principal,
        available: bool,
        category: (string-ascii 20)
    }
)

;; Public Functions

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
            (merge curator-existing-stats {collections: (+ u1 (get collections curator-existing-stats))}))
        (var-set next-collection-id (+ collection-id u1))
        (ok collection-id)
    )
)

;; Vote for a collection and distribute rewards
(define-public (vote-for-collection (collection-id uint))
    (let
        (
            (collection (unwrap! (map-get? collections collection-id) err-not-found))
            (creator (get creator collection))
            (curator-stats (default-to {collections: u0, total-votes: u0, reputation: u0, rewards-earned: u0} 
                (map-get? curator-stats creator)))
            (vote-reward u10)
        )
        (map-set collections collection-id
            (merge collection {votes: (+ u1 (get votes collection))}))
        
        ;; Update curator stats and distribute rewards
        (var-set reward-pool (+ (var-get reward-pool) vote-reward))
        (map-set curator-stats creator
            (merge curator-stats {
                total-votes: (+ u1 (get total-votes curator-stats)),
                reputation: (+ u10 (get reputation curator-stats)),
                rewards-earned: (+ vote-reward (get rewards-earned curator-stats))
            }))
        (ok true)
    )
)

;; Claim rewards for a collection
(define-public (claim-collection-rewards (collection-id uint))
    (let
        (
            (collection (unwrap! (map-get? collections collection-id) err-not-found))
            (rewards-available (calculate-rewards collection))
        )
        (asserts! (is-eq (get creator collection) tx-sender) err-unauthorized)
        (asserts! (not (get rewards-claimed collection)) err-unauthorized)
        (asserts! (>= (var-get reward-pool) rewards-available) err-unauthorized)
        
        (var-set reward-pool (- (var-get reward-pool) rewards-available))
        (map-set collections collection-id
            (merge collection {rewards-claimed: true}))
        (ok rewards-available)
    )
)

;; List item for sale
(define-public (list-item (name (string-ascii 100)) (description (string-ascii 500)) (price uint) (category (string-ascii 20)))
    (let
        ((item-id (len (map-get? items))))
        (asserts! (is-valid-category category) err-invalid-category)
        (map-set items item-id {
            name: name,
            description: description,
            price: price,
            category: category,
            seller: tx-sender,
            available: true
        })
        (ok item-id)
    )
)

;; Read-only functions

(define-read-only (get-collection (collection-id uint))
    (ok (map-get? collections collection-id))
)

(define-read-only (get-curator-stats (curator principal))
    (ok (map-get? curator-stats curator))
)

(define-read-only (get-reward-pool)
    (ok (var-get reward-pool))
)

;; Internal functions

(define-private (validate-items (items (list 10 uint)))
    (if (> (len items) u10)
        err-unauthorized
        (ok true)
    )
)

(define-private (is-valid-category (category (string-ascii 20)))
    (is-some (index-of categories category))
)

(define-private (calculate-rewards (collection (tuple (creator principal) (votes uint) (rewards-claimed bool))))
    (let
        ((base-reward u100)
         (vote-multiplier u5))
        (* (get votes collection) vote-multiplier)
    )
)
