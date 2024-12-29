;; TrendSphere Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var next-collection-id uint u0)

;; Data Maps
(define-map collections 
    uint 
    {
        creator: principal,
        title: (string-ascii 50),
        description: (string-ascii 500),
        items: (list 10 uint),
        votes: uint,
        created-at: uint
    }
)

(define-map curator-stats
    principal
    {
        collections: uint,
        total-votes: uint,
        reputation: uint
    }
)

(define-map items
    uint
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        price: uint,
        seller: principal,
        available: bool
    }
)

;; Public Functions

;; Create a new collection
(define-public (create-collection (title (string-ascii 50)) (description (string-ascii 500)) (items (list 10 uint)))
    (let
        (
            (collection-id (var-get next-collection-id))
            (curator-existing-stats (default-to {collections: u0, total-votes: u0, reputation: u0} 
                (map-get? curator-stats tx-sender)))
        )
        (try! (validate-items items))
        (map-set collections collection-id {
            creator: tx-sender,
            title: title,
            description: description,
            items: items,
            votes: u0,
            created-at: block-height
        })
        (map-set curator-stats tx-sender 
            (merge curator-existing-stats {collections: (+ u1 (get collections curator-existing-stats))}))
        (var-set next-collection-id (+ collection-id u1))
        (ok collection-id)
    )
)

;; Vote for a collection
(define-public (vote-for-collection (collection-id uint))
    (let
        (
            (collection (unwrap! (map-get? collections collection-id) err-not-found))
            (creator (get creator collection))
            (curator-stats (default-to {collections: u0, total-votes: u0, reputation: u0} 
                (map-get? curator-stats creator)))
        )
        (map-set collections collection-id
            (merge collection {votes: (+ u1 (get votes collection))}))
        (map-set curator-stats creator
            (merge curator-stats {
                total-votes: (+ u1 (get total-votes curator-stats)),
                reputation: (+ u10 (get reputation curator-stats))
            }))
        (ok true)
    )
)

;; List item for sale
(define-public (list-item (name (string-ascii 100)) (description (string-ascii 500)) (price uint))
    (let
        ((item-id (len (map-get? items))))
        (map-set items item-id {
            name: name,
            description: description,
            price: price,
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

;; Internal functions

(define-private (validate-items (items (list 10 uint)))
    (if (> (len items) u10)
        err-unauthorized
        (ok true)
    )
)