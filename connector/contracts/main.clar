(define-map volunteers
  ;; maps principal to a tuple (name, skills, location)
  principal { name: (string-ascii 50), skills: (string-ascii 100), location: (string-ascii 100) })

(define-map opportunities
  ;; maps id to a tuple (owner, description, date, filled)
  uint { owner: principal, description: (string-ascii 200), date: int, filled: bool })

(define-data-var next-opportunity-id uint u0)

;; Register a volunteer
(define-public (register-volunteer (name (string-ascii 50)) (skills (string-ascii 100)) (location (string-ascii 100)))
  (begin
    (asserts! (not (map-get? volunteers tx-sender)) (err u100))
    (map-set volunteers tx-sender { name: name, skills: skills, location: location })
    (ok true)))

;; Update volunteer profile
(define-public (update-volunteer (name (string-ascii 50)) (skills (string-ascii 100)) (location (string-ascii 100)))
  (begin
    (asserts! (map-get? volunteers tx-sender) (err u101))
    (map-set volunteers tx-sender { name: name, skills: skills, location: location })
    (ok true)))

;; Get volunteer info
(define-read-only (get-volunteer (addr principal))
  (match (map-get volunteers addr)
    entry (ok entry)
    none (err u102)))

;; Create an opportunity
(define-public (create-opportunity (description (string-ascii 200)) (date int))
  (begin
    (let ((id (var-get next-opportunity-id)))
      (map-set opportunities id { owner: tx-sender, description: description, date: date, filled: false })
      (var-set next-opportunity-id (+ id u1))
      (ok id))))

;; Get opportunity by id
(define-read-only (get-opportunity (id uint))
  (match (map-get opportunities id)
    entry (ok entry)
    none (err u200)))

;; Close opportunity (mark filled)
(define-public (close-opportunity (id uint))
  (begin
    (asserts! (map-get? opportunities id) (err u201))
    (let ((entry (unwrap-panic (map-get opportunities id))))
      (asserts! (is-eq (get owner entry) tx-sender) (err u202))
      (map-set opportunities id { owner: (get owner entry), description: (get description entry), date: (get date entry), filled: true })
      (ok true))))
