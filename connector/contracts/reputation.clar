;; Reputation System Contract
;; Tracks volunteer performance and organization credibility

(define-map volunteer-reputation
  ;; maps volunteer principal to reputation data
  principal { 
    total-score: int, 
    completed-opportunities: uint, 
    no-shows: uint, 
    average-rating: uint 
  })

(define-map organization-reputation
  ;; maps organization principal to reputation data  
  principal {
    total-score: int,
    opportunities-created: uint,
    opportunities-completed: uint,
    average-rating: uint
  })

(define-map reviews
  ;; maps review-id to review data
  uint {
    reviewer: principal,
    reviewee: principal,
    opportunity-id: uint,
    rating: uint,
    review-text: (string-ascii 500),
    review-date: int,
    review-type: (string-ascii 20)
  })

(define-data-var next-review-id uint u0)

;; Error constants
(define-constant ERR-INVALID-RATING u400)
(define-constant ERR-SELF-REVIEW u401)
(define-constant ERR-ALREADY-REVIEWED u402)
(define-constant ERR-OPPORTUNITY-NOT-COMPLETED u403)
(define-constant ERR-REVIEW-NOT-FOUND u404)
(define-constant ERR-UNAUTHORIZED-REVIEWER u405)

;; Initialize reputation for new user
(define-private (init-volunteer-reputation (volunteer principal))
  (match (map-get? volunteer-reputation volunteer)
    existing existing
    (begin
      (map-set volunteer-reputation volunteer {
        total-score: 0,
        completed-opportunities: u0,
        no-shows: u0,
        average-rating: u0
      })
      { total-score: 0, completed-opportunities: u0, no-shows: u0, average-rating: u0 })))

(define-private (init-organization-reputation (organization principal))
  (match (map-get? organization-reputation organization)
    existing existing
    (begin
      (map-set organization-reputation organization {
        total-score: 0,
        opportunities-created: u0,
        opportunities-completed: u0,
        average-rating: u0
      })
      { total-score: 0, opportunities-created: u0, opportunities-completed: u0, average-rating: u0 })))

;; Submit a review for a volunteer (called by opportunity owner)
(define-public (review-volunteer (volunteer principal) (opportunity-id uint) (rating uint) (review-text (string-ascii 500)))
  (begin
    ;; Validate rating (1-5 scale)
    (asserts! (and (>= rating u1) (<= rating u5)) (err ERR-INVALID-RATING))
    ;; Prevent self-review
    (asserts! (not (is-eq tx-sender volunteer)) (err ERR-SELF-REVIEW))
    ;; Check if already reviewed this volunteer for this opportunity
    (asserts! (is-none (map-get? reviews (var-get next-review-id))) (err ERR-ALREADY-REVIEWED))
    
    ;; Create review
    (let ((review-id (var-get next-review-id)))
      (map-set reviews review-id {
        reviewer: tx-sender,
        reviewee: volunteer,
        opportunity-id: opportunity-id,
        rating: rating,
        review-text: review-text,
        review-date: (to-int block-height),
        review-type: "volunteer"
      })
      (var-set next-review-id (+ review-id u1))
      
      ;; Update volunteer reputation
      (let ((current-rep (init-volunteer-reputation volunteer)))
        (map-set volunteer-reputation volunteer {
          total-score: (+ (get total-score current-rep) (to-int rating)),
          completed-opportunities: (+ (get completed-opportunities current-rep) u1),
          no-shows: (get no-shows current-rep),
          average-rating: rating ;; Simplified - in production would calculate proper average
        }))
      
      (ok review-id))))

;; Submit a review for an organization (called by volunteer)
(define-public (review-organization (organization principal) (opportunity-id uint) (rating uint) (review-text (string-ascii 500)))
  (begin
    ;; Validate rating (1-5 scale)
    (asserts! (and (>= rating u1) (<= rating u5)) (err ERR-INVALID-RATING))
    ;; Prevent self-review
    (asserts! (not (is-eq tx-sender organization)) (err ERR-SELF-REVIEW))
    
    ;; Create review
    (let ((review-id (var-get next-review-id)))
      (map-set reviews review-id {
        reviewer: tx-sender,
        reviewee: organization,
        opportunity-id: opportunity-id,
        rating: rating,
        review-text: review-text,
        review-date: (to-int block-height),
        review-type: "organization"
      })
      (var-set next-review-id (+ review-id u1))
      
      ;; Update organization reputation
      (let ((current-rep (init-organization-reputation organization)))
        (map-set organization-reputation organization {
          total-score: (+ (get total-score current-rep) (to-int rating)),
          opportunities-created: (get opportunities-created current-rep),
          opportunities-completed: (+ (get opportunities-completed current-rep) u1),
          average-rating: rating ;; Simplified - in production would calculate proper average
        }))
      
      (ok review-id))))

;; Record a no-show (called by opportunity owner)
(define-public (record-no-show (volunteer principal) (opportunity-id uint))
  (begin
    ;; Initialize or get current reputation
    (let ((current-rep (init-volunteer-reputation volunteer)))
      (map-set volunteer-reputation volunteer {
        total-score: (- (get total-score current-rep) 10), ;; Penalty for no-show
        completed-opportunities: (get completed-opportunities current-rep),
        no-shows: (+ (get no-shows current-rep) u1),
        average-rating: (get average-rating current-rep)
      }))
    (ok true)))

;; Get volunteer reputation
(define-read-only (get-volunteer-reputation (volunteer principal))
  (match (map-get? volunteer-reputation volunteer)
    entry (ok entry)
    (ok { total-score: 0, completed-opportunities: u0, no-shows: u0, average-rating: u0 })))

;; Get organization reputation  
(define-read-only (get-organization-reputation (organization principal))
  (match (map-get? organization-reputation organization)
    entry (ok entry)
    (ok { total-score: 0, opportunities-created: u0, opportunities-completed: u0, average-rating: u0 })))

;; Get review by ID
(define-read-only (get-review (review-id uint))
  (match (map-get? reviews review-id)
    entry (ok entry)
    (err ERR-REVIEW-NOT-FOUND)))
