;; Local Volunteer Connector - Enhanced Main Contract
;; Bug fixes and security improvements

(define-map volunteers
  ;; maps principal to a tuple (name, skills, location, active)
  principal { name: (string-ascii 50), skills: (string-ascii 100), location: (string-ascii 100), active: bool })

(define-map opportunities
  ;; maps id to a tuple (owner, description, date, filled, required-skills)
  uint { owner: principal, description: (string-ascii 200), date: int, filled: bool, required-skills: (string-ascii 100) })

(define-map volunteer-applications
  ;; maps (opportunity-id, volunteer) to application status
  { opportunity-id: uint, volunteer: principal } { status: (string-ascii 20), application-date: int })

(define-data-var next-opportunity-id uint u0)
(define-data-var contract-owner principal tx-sender)

;; Error constants
(define-constant ERR-ALREADY-REGISTERED u100)
(define-constant ERR-NOT-REGISTERED u101)
(define-constant ERR-VOLUNTEER-NOT-FOUND u102)
(define-constant ERR-OPPORTUNITY-NOT-FOUND u200)
(define-constant ERR-OPPORTUNITY-DOES-NOT-EXIST u201)
(define-constant ERR-NOT-OPPORTUNITY-OWNER u202)
(define-constant ERR-OPPORTUNITY-FILLED u203)
(define-constant ERR-ALREADY-APPLIED u204)
(define-constant ERR-INVALID-DATE u205)
(define-constant ERR-VOLUNTEER-INACTIVE u206)
(define-constant ERR-UNAUTHORIZED u300)

;; Input validation functions
(define-private (is-valid-date (date int))
  (> date (to-int block-height)))

(define-private (is-string-valid (str (string-ascii 200)))
  (> (len str) u0))

;; Register a volunteer
(define-public (register-volunteer (name (string-ascii 50)) (skills (string-ascii 100)) (location (string-ascii 100)))
  (begin
    ;; Input validation
    (asserts! (is-string-valid name) (err ERR-VOLUNTEER-NOT-FOUND))
    (asserts! (is-string-valid location) (err ERR-VOLUNTEER-NOT-FOUND))
    ;; Check if already registered
    (asserts! (is-none (map-get? volunteers tx-sender)) (err ERR-ALREADY-REGISTERED))
    ;; Register volunteer as active by default
    (map-set volunteers tx-sender { name: name, skills: skills, location: location, active: true })
    (ok true)))

;; Update volunteer profile
(define-public (update-volunteer (name (string-ascii 50)) (skills (string-ascii 100)) (location (string-ascii 100)))
  (begin
    ;; Input validation
    (asserts! (is-string-valid name) (err ERR-VOLUNTEER-NOT-FOUND))
    (asserts! (is-string-valid location) (err ERR-VOLUNTEER-NOT-FOUND))
    ;; Check if registered
    (asserts! (is-some (map-get? volunteers tx-sender)) (err ERR-NOT-REGISTERED))
    ;; Preserve active status when updating
    (let ((current-volunteer (unwrap-panic (map-get? volunteers tx-sender))))
      (map-set volunteers tx-sender { 
        name: name, 
        skills: skills, 
        location: location, 
        active: (get active current-volunteer) 
      })
      (ok true))))

;; Toggle volunteer active status
(define-public (toggle-volunteer-status)
  (begin
    (asserts! (is-some (map-get? volunteers tx-sender)) (err ERR-NOT-REGISTERED))
    (let ((current-volunteer (unwrap-panic (map-get? volunteers tx-sender))))
      (map-set volunteers tx-sender {
        name: (get name current-volunteer),
        skills: (get skills current-volunteer),
        location: (get location current-volunteer),
        active: (not (get active current-volunteer))
      })
      (ok (not (get active current-volunteer))))))

;; Get volunteer info
(define-read-only (get-volunteer (addr principal))
  (match (map-get? volunteers addr)
    entry (ok entry)
    (err ERR-VOLUNTEER-NOT-FOUND)))

;; Create an opportunity with enhanced validation
(define-public (create-opportunity (description (string-ascii 200)) (date int) (required-skills (string-ascii 100)))
  (begin
    ;; Input validation
    (asserts! (is-string-valid description) (err ERR-OPPORTUNITY-NOT-FOUND))
    (asserts! (is-valid-date date) (err ERR-INVALID-DATE))
    ;; Ensure creator is a registered volunteer
    (asserts! (is-some (map-get? volunteers tx-sender)) (err ERR-NOT-REGISTERED))
    (let ((id (var-get next-opportunity-id)))
      (map-set opportunities id { 
        owner: tx-sender, 
        description: description, 
        date: date, 
        filled: false,
        required-skills: required-skills 
      })
      (var-set next-opportunity-id (+ id u1))
      (ok id))))

;; Get opportunity by id
(define-read-only (get-opportunity (id uint))
  (match (map-get? opportunities id)
    entry (ok entry)
    (err ERR-OPPORTUNITY-NOT-FOUND)))

;; Apply for an opportunity
(define-public (apply-for-opportunity (opportunity-id uint))
  (begin
    ;; Check if opportunity exists
    (asserts! (is-some (map-get? opportunities opportunity-id)) (err ERR-OPPORTUNITY-DOES-NOT-EXIST))
    ;; Check if volunteer is registered and active
    (let ((volunteer-info (unwrap-panic (map-get? volunteers tx-sender))))
      (asserts! (get active volunteer-info) (err ERR-VOLUNTEER-INACTIVE))
      ;; Check if opportunity is still open
      (let ((opportunity (unwrap-panic (map-get? opportunities opportunity-id))))
        (asserts! (not (get filled opportunity)) (err ERR-OPPORTUNITY-FILLED))
        ;; Check if already applied
        (asserts! (is-none (map-get? volunteer-applications { opportunity-id: opportunity-id, volunteer: tx-sender })) (err ERR-ALREADY-APPLIED))
        ;; Create application
        (map-set volunteer-applications 
          { opportunity-id: opportunity-id, volunteer: tx-sender }
          { status: "pending", application-date: (to-int block-height) })
        (ok true)))))

;; Close opportunity (mark filled) - Fixed bug: now checks if opportunity exists first
(define-public (close-opportunity (id uint))
  (begin
    ;; Check if opportunity exists first (bug fix)
    (asserts! (is-some (map-get? opportunities id)) (err ERR-OPPORTUNITY-DOES-NOT-EXIST))
    (let ((entry (unwrap-panic (map-get? opportunities id))))
      ;; Check ownership
      (asserts! (is-eq (get owner entry) tx-sender) (err ERR-NOT-OPPORTUNITY-OWNER))
      ;; Mark as filled
      (map-set opportunities id { 
        owner: (get owner entry), 
        description: (get description entry), 
        date: (get date entry), 
        filled: true,
        required-skills: (get required-skills entry)
      })
      (ok true))))

;; Get application status
(define-read-only (get-application-status (opportunity-id uint) (volunteer principal))
  (match (map-get? volunteer-applications { opportunity-id: opportunity-id, volunteer: volunteer })
    entry (ok entry)
    (err ERR-OPPORTUNITY-NOT-FOUND)))

;; Emergency pause function (only contract owner)
(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-UNAUTHORIZED))
    (ok true)))
