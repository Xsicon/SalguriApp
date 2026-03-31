# Salguri Platform: Developer Questions & Clarifications Document

## PART 1: AUTHENTICATION & USER MANAGEMENT QUESTIONS

### 1.1 Registration & Account Creation

**Q1: Do we need social login (Google, Apple) for diaspora users?**
**A1:** Yes, implement social login for diaspora users.
- Google Sign-In is required for diaspora users who may not have Somali phone numbers
- Apple Sign-In is mandatory for iOS app compliance with App Store guidelines
- Facebook Login can be added in Phase 2

Deliverables:
- Google Sign-In integration for web and mobile
- Apple Sign-In integration for iOS app
- Account linking logic to merge social accounts with existing phone-based accounts
- Clear user interface showing all login options

---

**Q2: How do we handle users who have both a Customer App account and work for a Business App company?**
**A2:** Users will have a single identity that works across both apps with role switching.
- One user = One account (phone number or email as primary identifier)
- The system detects which app they're using and shows appropriate interface
- Users can switch between "Customer Mode" and "Employee Mode" from profile
- Notifications from both roles appear in a unified inbox
- Personal data (saved properties, etc.) remains separate from work data

Deliverables:
- Unified user database with role-based profiles
- Role switching mechanism in app UI
- Unified notification center showing messages from all roles
- Clear visual indicators showing current active mode

---

**Q3: Can a user have multiple roles (e.g., Property Owner in Customer App and Agent in Business App)?**
**A3:** Yes, users can hold multiple roles across both applications.
- Allowed combinations: Property Owner + Agent, Tenant + Property Manager, Service Requester + Technician
- Not allowed: Working for two competing companies simultaneously
- Each role has its own permissions and dashboard view
- Users cannot access business features from customer app and vice versa

Deliverables:
- Role combination matrix defining all valid combinations
- Permission system that supports multiple concurrent roles
- Clear UI showing which role is currently active
- Audit log tracking actions across all roles

---

**Q4: What's the process for a Customer App user who wants to become a Business App company owner?**
**A4:** Seamless upgrade path with data preservation.
- Customer clicks "Switch to Business" or "Register Company" in profile
- Company registration form pre-fills with existing customer data
- User uploads business documents for verification
- Admin reviews within 24-48 hours
- Upon approval, user gains Business App access while retaining customer profile
- Properties owned as customer can optionally transfer to business portfolio

Deliverables:
- "Upgrade to Business" button in customer profile
- Company registration form with data pre-fill
- Document upload interface for verification
- Admin review queue for business applications
- Role upgrade notification system

---

**Q5: Do we allow registration without phone verification for diaspora users who don't have Somali numbers?**
**A5:** Yes, tiered verification based on user location and intent.
- Somalia-based users: Must verify with Somali phone number (SMS)
- Diaspora users: Can register with email and international phone (optional)
- All users: Phone verification becomes mandatory before any financial transaction
- Business users: Always require verified contact method regardless of location

Deliverables:
- Location detection during registration (IP-based + user selection)
- Flexible verification flows based on user type
- Clear messaging about verification requirements for transactions
- Graceful upgrade path from email-only to verified status

---

**Q6: How do we handle users who lose access to their registered phone number?**
**A6:** Multi-step recovery process with identity verification.
- Option 1: Email recovery (if email was registered)
- Option 2: Social account recovery (if linked)
- Option 3: Identity verification portal - upload government ID
- Support team manually reviews within 24 hours
- Upon verification, phone number can be updated
- All recovery attempts are logged for security

Deliverables:
- Account recovery flow with multiple options
- Identity verification portal with document upload
- Support dashboard for manual review
- Security alert system for recovery attempts
- Audit log of all recovery actions

---

**Q7: What's the minimum age requirement for registration?**
**A7:** Users must be at least 18 years old.
- All users must confirm they are 18+ during registration
- No formal age verification at signup (privacy considerations)
- Property ownership and contracts legally require adulthood
- If underage user is discovered, account is suspended and parent/guardian contact attempted
- Business owners must provide business registration confirming legal adult status

Deliverables:
- Age confirmation checkbox in registration
- Terms of service explicitly stating age requirement
- Account suspension process for underage users
- Reporting mechanism for suspected underage users

---

**Q8: Do we need parental consent for users under 18?**
**A8:** No, users under 18 are not permitted on the platform.
- Platform strictly prohibits users under 18
- No parental consent mechanism will be implemented
- If underage user is detected, account is immediately suspended
- Exception: View-only access with parent supervision (Phase 2 consideration)

Deliverables:
- Clear age restriction messaging in signup
- Automated account suspension for age violations
- Support process for handling underage account reports

---

**Q9: How do we handle registration for non-Somali speaking users?**
**A9:** Multi-language support from day one.
- App supports Somali, English, and Arabic at launch
- Users select preferred language during registration
- All system messages, emails, and notifications use selected language
- Content can be translated by users (AI translation in Phase 2)
- Support team has multilingual capabilities

Deliverables:
- Language selector at registration
- Full UI translation for Somali, English, Arabic
- Multi-language notification templates
- Language preference saved to user profile

---

**Q10: Can companies register with multiple branches/locations under one account?**
**A10:** Yes, companies can manage multiple locations from a single account.
- One company account with one Owner/Admin
- Company can add multiple branches/locations
- Each branch can have its own address, phone, and team
- Branches share company verification status
- Reports can be viewed by branch or consolidated
- Employees can be assigned to specific branches

Deliverables:
- Branch management interface in company settings
- Location-based team assignment
- Consolidated and branch-level reporting
- Branch-specific service areas and pricing

---

### 1.2 Login & Session Management

**Q11: How many concurrent sessions should a user be allowed?**
**A11:** Unlimited sessions, with security notifications.
- Users can be logged in on multiple devices simultaneously
- New device login triggers notification (email/SMS)
- Users can view and manage active sessions from profile
- Option to "logout all other devices" available
- Suspicious activity monitoring for unusual patterns

Deliverables:
- Active session management page in user profile
- New device login notification system
- Remote logout capability
- Session history with device information

---

**Q12: What's the session timeout duration?**
**A12:** Configurable timeout with warning.
- Mobile app: 30 days (refresh token), users stay logged in
- Web app: 24 hours inactivity timeout
- Warning: 5-minute warning before timeout
- Sensitive actions (payments, contracts) require recent authentication
- Admin can configure timeout policies for their company

Deliverables:
- Session timeout mechanism with warning
- Refresh token strategy for mobile
- Re-authentication for sensitive actions
- Admin-configurable timeout settings

---

**Q13: Should we implement "remember me" functionality?**
**A13:** Yes, with clear user choice.
- "Remember me" checkbox on login
- If checked: 30-day persistent session
- If unchecked: Session expires when browser closes (web) or 24 hours
- Option available on both web and mobile
- Security notice explaining the choice

Deliverables:
- Remember me checkbox on login screen
- Session duration logic based on user choice
- Clear explanation of security implications

---

**Q14: How do we handle password recovery for users without email?**
**A14:** SMS-based recovery for phone-only users.
- Users can recover via SMS to registered phone number
- 6-digit verification code sent via SMS
- After verification, user can set new password
- Alternative: Call support for manual recovery (with ID verification)
- All recovery attempts logged

Deliverables:
- SMS-based password recovery flow
- 6-digit verification code system
- Support-assisted recovery process
- Recovery attempt logging and monitoring

---

**Q15: Should we implement biometric login (fingerprint/face ID) for mobile apps?**
**A15:** Yes, for enhanced user experience.
- Biometric login available after initial password login
- Supported on devices with fingerprint or face recognition
- User opt-in only (not mandatory)
- Fallback to password always available
- Biometric data never leaves the device

Deliverables:
- Biometric login option in app settings
- Secure local storage of biometric tokens
- Clear opt-in flow with privacy explanation
- Fallback authentication methods

---

**Q16: How do we handle session invalidation when a user's role changes?**
**A16:** Immediate session update with notification.
- When role changes (promotion, demotion, termination), active sessions are updated
- User receives notification of role change
- For termination, all sessions are immediately revoked
- User must log in again to refresh permissions
- Audit log records all role change events

Deliverables:
- Real-time permission update mechanism
- Session revocation for terminated employees
- Notification system for role changes
- Audit trail for all permission changes

---

**Q17: What's the process for force logout by admin?**
**A17:** Admin can terminate any user session.
- Admin dashboard has "Force Logout" button for any user
- Reason for logout must be provided (logged)
- User receives notification "You have been logged out by administrator"
- User cannot log back in if account is suspended
- All force logout actions are audited

Deliverables:
- Force logout functionality in admin dashboard
- Reason collection and logging
- User notification system
- Audit log for all admin actions

---

**Q18: How do we handle login from new devices - require verification?**
**A18:** Optional two-factor with notification.
- New device login triggers notification to user
- User can choose to enable 2FA for new devices (optional)
- For high-risk actions (payments), additional verification required
- Users can view all trusted devices in profile
- Option to remove trusted devices

Deliverables:
- New device detection and notification
- Optional 2FA for new devices
- Trusted device management interface
- Risk-based authentication for sensitive actions

---

**Q19: Should we implement login attempt limiting and temporary locks?**
**A19:** Yes, for security.
- 5 failed attempts = 15-minute temporary lock
- 10 failed attempts = 1-hour lock + admin notification
- Captcha after 3 failed attempts
- Lock duration increases with repeated failures
- User notified of locks via email/SMS
- Support can manually unlock

Deliverables:
- Failed attempt tracking system
- Progressive lockout mechanism
- Captcha integration
- User notification for locks
- Support unlock capability

---

**Q20: How do we handle SSO for large companies with existing systems?**
**A20:** Enterprise SSO option for Phase 2.
- MVP: Standard login only
- Phase 2: Enterprise SSO (SAML, OAuth, LDAP)
- Companies can integrate with their existing identity systems
- Custom domain support for enterprise login pages
- SCIM support for user provisioning/deprovisioning

Deliverables (Phase 2):
- SAML 2.0 integration
- OAuth 2.0 / OIDC support
- Custom domain login pages
- SCIM user provisioning
- Enterprise admin configuration interface

---

### 1.3 Role & Permission Questions

**Q21: Can a Company Owner have multiple admins with equal permissions?**
**A21:** Yes, with one primary owner.
- One "Primary Owner" with full ownership rights (cannot be removed by others)
- Multiple "Admins" with nearly all permissions except:
  - Cannot delete the company
  - Cannot remove the Primary Owner
  - Cannot change ownership
- Admins can manage employees, finances, and settings
- Clear hierarchy visible in team management

Deliverables:
- Primary Owner designation in company setup
- Admin role with configurable permissions
- Team management interface showing hierarchy
- Safeguards preventing admin from removing owner

---

**Q22: How do we handle temporary role assignments (vacation coverage)?**
**A22:** Temporary role assignment with expiration.
- Admins can assign temporary roles with start/end dates
- User receives notification of temporary permissions
- Permissions automatically expire on end date
- Audit log tracks temporary assignments
- Option to extend or revoke early

Deliverables:
- Temporary role assignment interface
- Date-based permission expiration
- Notification system for temporary assignments
- Audit trail for temporary permissions

---

**Q23: Can permissions be customized per employee beyond standard roles?**
**A23:** Yes, with role templates and custom overrides.
- Standard role templates (Agent, Technician, etc.) with default permissions
- Admins can customize permissions per employee within limits
- Custom permissions are saved as "variants" for reuse
- Permission changes are audited
- Company owner sets maximum permission boundaries

Deliverables:
- Permission customization interface
- Role template system with variants
- Permission boundaries configuration
- Audit log for custom permissions

---

**Q24: How do we handle role changes for employees (promotions)?**
**A24:** Structured role change workflow.
- Admin initiates role change from employee profile
- Select new role and effective date
- System validates permission compatibility
- Employee notified of upcoming change
- Old permissions revoked, new granted on effective date
- Audit log records all role changes

Deliverables:
- Role change workflow interface
- Scheduled role change capability
- Employee notification system
- Permission transition validation
- Complete audit trail

---

**Q25: What happens to an employee's assigned tasks when their role is changed?**
**A25:** Tasks remain but may require reassignment.
- Existing tasks remain assigned to the employee
- If new role lacks permissions for certain tasks, employee is notified
- Manager receives alert about permission gaps
- Tasks can be reassigned manually
- Incomplete tasks highlighted for review
- No automatic task deletion

Deliverables:
- Task reassignment workflow
- Permission gap detection and alerts
- Manager notification system
- Task status preservation during role changes

---

**Q26: Can an employee work for multiple companies simultaneously?**
**A26:** No, one active employment at a time.
- Each user can be actively employed by only one company
- Users can have customer profile plus one business profile
- If employee wants to switch companies, they must leave current one
- Former company data preserved but access revoked
- Exception: Consultants/freelancers (Phase 2 with special account type)

Deliverables:
- Employment status tracking
- Company switching workflow (terminate + join)
- Data access revocation for former employees
- Clear communication about employment limits

---

**Q27: How do we handle department-based permissions within large companies?**
**A27:** Department structure with manager hierarchy.
- Companies can create departments (Sales, Maintenance, Accounting)
- Department heads can manage their team's permissions
- Cross-department permissions require admin approval
- Reports can be filtered by department
- Budgets and targets can be set per department

Deliverables:
- Department creation and management
- Department head role with limited admin powers
- Cross-department permission workflow
- Department-based reporting
- Budget allocation per department

---

**Q28: Can a Company Owner delegate specific approval authority?**
**A28:** Yes, granular approval delegation.
- Owner can delegate approval authority for:
  - Expense approvals (up to amount limit)
  - Contract approvals
  - Leave requests
  - Purchase orders
- Each delegation can have amount limits
- Delegation can be temporary or permanent
- Owner still receives notification of approvals

Deliverables:
- Approval delegation interface
- Amount limits for delegated authority
- Temporary delegation with expiration
- Notification system for delegated approvals
- Audit trail of all approvals

---

**Q29: How do we audit permission changes?**
**A29:** Comprehensive permission audit log.
- Every permission change is logged with:
  - Who made the change
  - What was changed (before/after)
  - When it happened
  - Why (reason field for admins)
- Audit log viewable by company owner and platform admin
- Exportable for compliance purposes
- Retention: 7 years (legal requirement)

Deliverables:
- Permission audit database
- Audit log viewer interface
- Export functionality (CSV, PDF)
- Retention policy implementation
- Search and filter capabilities

---

**Q30: What's the hierarchy when multiple managers have conflicting permissions?**
**A30:** Clear hierarchy with override rules.
- Hierarchy level 1: Platform Admin (overrides all)
- Hierarchy level 2: Company Owner
- Hierarchy level 3: Company Admins
- Hierarchy level 4: Department Heads
- Hierarchy level 5: Team Leads
- Rule: Higher level always overrides lower
- Same level: Most restrictive permission wins (security principle)
- Conflict resolution: System flags conflicts for review

Deliverables:
- Permission hierarchy implementation
- Conflict detection and resolution logic
- Admin notification for permission conflicts
- Clear documentation of permission rules

---

## PART 2: CUSTOMER APP FUNCTIONALITY QUESTIONS

### 2.1 Property Discovery & Search

**Q31: What search filters are MVP vs. phase 2?**
**A31:** Clear MVP and Phase 2 filter sets.

| Filter Category | MVP Filters | Phase 2 Filters |
|---|---|---|
| Location | City, District | Neighborhood, proximity to landmarks |
| Price | Min/Max range | Price per sqm, monthly payment estimate |
| Property Type | House, Apartment, Land | Villa, Commercial, Office, Warehouse |
| Bedrooms | 1-5+ | Studio, 6+ |
| Bathrooms | 1-4+ | Half baths, en-suites |
| Size | Min/Max sqm | Land area, built-up area |
| Status | For Sale, For Rent | Under construction, Pre-selling, Foreclosure |
| Features | Furnished, Parking, AC | Pool, Garden, Security, Elevator, Maid room |
| Advanced | - | Virtual tours, 3D walkthrough, Nearby amenities |

Deliverables:
- MVP filter bar with 8 core filters
- Phase 2 filter expansion architecture
- Filter persistence in URL for sharing
- Mobile-optimized filter drawer

---

**Q32: How do we handle location search with Somali district names?**
**A32:** Hierarchical location database with local names.
- Pre-populated database of Somali cities and districts
- Support for local spelling variations (Hodan/Hawad, Hamar/Xamar)
- Autocomplete as user types
- Map-based selection for precise location
- "Near me" option using device GPS
- Districts grouped by city for easy browsing

Deliverables:
- Complete Somalia location database (18 regions, 90+ districts)
- Autocomplete search with spelling variations
- Map-based location picker
- GPS location detection with user permission
- Location hierarchy navigation

---

**Q33: Should we implement map view with property pins?**
**A33:** Yes, map view is essential.
- Toggle between list view and map view
- Property pins on map with price indicators
- Cluster pins when zoomed out
- Tap pin shows property summary card
- Filter results update map in real-time
- Draw search area on map (Phase 2)

Deliverables:
- Interactive map integration (Google Maps/OpenStreetMap)
- Property pin clustering
- Map/list view toggle
- Real-time filter sync with map
- Property summary card on pin tap

---

**Q34: How do we handle properties with no exact GPS coordinates?**
**A34:** Approximate location with clear labeling.
- Properties without exact coordinates show district-level location
- Label: "Approximate location - Hodan District"
- Map pin placed at district center
- "Exact location provided upon inquiry" notice
- Agents can submit coordinates during listing
- Option to show street-level only (no exact pin)

Deliverables:
- District-level fallback for missing coordinates
- Clear labeling for approximate locations
- Agent interface to add/update coordinates
- Privacy option for sensitive properties

---

**Q35: What's the default search radius when user allows location access?**
**A35:** Progressive radius based on results.
- Default: 5km radius
- If few results (<10), auto-expand to 10km
- If still few, expand to 20km with notice
- User can manually adjust radius
- Radius saved per user preference
- Option to search entire city

Deliverables:
- Default radius (5km) implementation
- Smart radius expansion logic
- Manual radius slider control
- User preference storage

---

**Q36: How do we sort search results (relevance, price, newest, distance)?**
**A36:** Multiple sort options with default "relevance".

| Sort Option | Description | Default MVP? |
|---|---|---|
| Recommended | AI-based relevance (views, matches, recency) | Yes (default) |
| Price: Low to High | Cheapest first | Yes |
| Price: High to Low | Most expensive first | Yes |
| Newest | Recently listed | Yes |
| Distance | Nearest to user location | Yes |
| Size | Largest first | Phase 2 |
| Most Viewed | Popular listings | Phase 2 |

Deliverables:
- Sort dropdown with 5 options
- Relevance algorithm (basic version for MVP)
- Sort persistence in session
- Clear indication of current sort

---

**Q37: Should we implement saved searches and alerts?**
**A37:** Yes, core engagement feature.
- Users can save any search with all filters
- Name their saved searches (e.g., "3-bed houses in Hodan")
- Set alert frequency: Daily, Weekly, Instant
- Receive push/email/SMS when new matching properties listed
- Manage all saved searches from profile
- One-click re-run saved search

Deliverables:
- Save search button on results page
- Saved searches management page
- Alert frequency settings
- Notification system for new matches
- One-click search execution

---

**Q38: How do we handle properties that cross district boundaries?**
**A38:** Primary location assignment with cross-listing.
- Property assigned one primary district
- "Adjacent to" feature for neighboring districts
- Shows in searches for both districts with clear label
- Example: "Located on Hodan/Waberi border"
- Agents can select multiple districts during listing

Deliverables:
- Multi-district property tagging
- Clear border location labeling
- Agent interface for border properties
- Search inclusion logic for adjacent districts

---

**Q39: What's the fallback when no properties match search criteria?**
**A39:** Smart suggestions and expansion options.
- Friendly message: "No exact matches found"
- Show similar properties with adjusted filters
- Option to expand radius automatically
- Suggest removing least important filter
- Show recently viewed/saved properties
- Option to create alert for this search

Deliverables:
- No-results state design
- Similar property suggestions
- One-click filter relaxation
- Save search prompt on no results

---

**Q40: How do we handle multilingual property addresses (Somali, English, Arabic)?**
**A40:** Multi-field address storage.
- Address stored in three language fields
- Display based on user's language preference
- Search works across all language fields
- Agents can enter address in multiple languages
- Example: "Mogadishu" appears for English users, "Muqdisho" for Somali users

Deliverables:
- Multi-language address fields in database
- Language-specific display logic
- Cross-language search capability
- Agent entry interface with language tabs

---

### 2.2 Property Details & Viewing

**Q41: What's the maximum number of photos per property?**
**A41:** 20 photos for MVP, expandable later.
- MVP: Maximum 20 photos per property
- Phase 2: Unlimited with storage limits
- First photo is cover/thumbnail
- Supported formats: JPG, PNG, WEBP
- Maximum file size: 10MB per photo
- Automatic compression and optimization

Deliverables:
- Photo upload limit (20)
- File type and size validation
- Automatic image optimization
- Cover photo selection interface
- Photo reordering capability

---

**Q42: Should we support 360-degree virtual tours?**
**A42:** Phase 2 feature.
- MVP: Standard photos and videos only
- Phase 2: 360-degree photo support
- Phase 3: Full 3D virtual tours
- External integration with Matterport or similar
- Tour indicator on property cards
- Mobile VR headset compatibility

Deliverables (Phase 2):
- 360 photo upload and viewer
- External tour platform integration
- Tour thumbnail and indicator
- VR mode support

---

**Q43: How do we handle video walkthroughs?**
**A43:** YouTube/Vimeo integration.
- Agents can embed YouTube or Vimeo links
- Videos play directly in property page
- Maximum 3 videos per property
- Video thumbnail shown in gallery
- Option to upload directly (Phase 2, requires CDN)

Deliverables:
- Video URL field in property form
- Embedded video player
- Video thumbnail generation
- Video count limit (3)

---

**Q44: What property details are mandatory vs. optional?**
**A44:** Clear mandatory fields for listing quality.

| Section | Mandatory Fields | Optional Fields |
|---|---|---|
| Basic Info | Title, Description, Type, Price | Year built, Condition |
| Location | City, District | Exact coordinates, Street name |
| Size | Area (sqm) | Land area, Built-up area |
| Rooms | Bedrooms, Bathrooms | Study room, Storage |
| Features | - | Furnished, Parking, AC, Pool, Garden, Security |
| Media | At least 1 photo | Additional photos, Video, Virtual tour |
| Contact | Agent/Company | Alternate phone, WhatsApp |

Deliverables:
- Form validation with mandatory field checking
- Clear visual indicators for required fields
- Warning when publishing with missing optional fields
- Quality score based on completed fields

---

**Q45: How do we display availability status (for rent/sale, pending, rented/sold)?**
**A45:** Color-coded status badges.

| Status | Color | Description |
|---|---|---|
| Available | Green | Actively for sale/rent |
| Pending | Yellow | Offer accepted, under contract |
| Sold | Gray | Property sold |
| Rented | Gray | Property rented |
| Off Market | Gray | Temporarily unavailable |
| Coming Soon | Blue | Not yet listed |

Deliverables:
- Status badge component with colors
- Status update workflow for agents
- Automatic status changes (e.g., listing expiration)
- Search filter by status

---

**Q46: Should we show similar/recommended properties?**
**A46:** Yes, for engagement.
- "Similar Properties" section on property detail page
- Based on: same district, similar price range, similar size
- Maximum 6 recommendations
- Exclude current property
- Refresh on page reload
- Track clicks for algorithm improvement

Deliverables:
- Recommendation engine (basic rules-based)
- Similar properties carousel component
- Click tracking for recommendations
- A/B testing framework for algorithm (Phase 2)

---

**Q47: How do we handle properties with multiple units (apartment buildings)?**
**A47:** Parent-child property structure.
- Parent property = Building/Complex
- Child properties = Individual units
- Parent page shows building details and available units
- Each unit has its own price, status, and features
- Search shows individual units, not building
- Agents manage units from building dashboard

Deliverables:
- Parent-child property relationship in database
- Building view with unit list
- Individual unit management interface
- Unit status tracking
- Consolidated building analytics

---

**Q48: What's the process for reporting incorrect property information?**
**A48:** User reporting with review workflow.
- "Report" button on every property
- Report reasons: Wrong price, Wrong location, Sold/Rented, Spam, Other
- Report goes to platform moderation queue
- Moderator reviews within 24 hours
- If valid, property flagged and agent notified
- Multiple reports trigger automatic review

Deliverables:
- Report property interface
- Moderation queue dashboard
- Agent notification for reports
- Automatic flagging system
- Report history tracking

---

**Q49: Should we show property history (price changes, listing duration)?**
**A49:** Yes, for transparency (Phase 2).
- MVP: Current price only
- Phase 2: Price history graph
- Show all price changes with dates
- Days on market counter
- Previous listings (if relisted)
- Available to logged-in users only

Deliverables (Phase 2):
- Price change tracking
- Days on market calculation
- History graph component
- Relisting detection logic

---

**Q50: How do we handle properties with no photos yet?**
**A50:** Placeholder with agent contact prompt.
- Default placeholder image: "Photos coming soon"
- Prominent message encouraging agent to add photos
- Option for user to "Request photos" (notifies agent)
- Lower in search rankings (quality score penalty)
- Agent dashboard reminder to add photos

Deliverables:
- Placeholder image component
- "Request photos" button
- Agent notification system
- Search ranking penalty for no photos

---

### 2.3 Contact & Communication

**Q51: Can users contact agents without creating an account?**
**A51:** No, account required for contact.
- Users must create account to contact agents
- Prevents spam and anonymous inquiries
- Captures user info for agent follow-up
- Users can browse without account
- Guest mode: Browse only, no contact
- Clear CTA: "Sign up to contact agent"

Deliverables:
- Account wall on contact actions
- Guest mode implementation
- Clear sign-up prompts
- Inquiry tracking per user

---

**Q52: What information is shared with agents when user contacts them?**
**A52:** Essential contact information only.
- Shared automatically: Name, Phone number, Email
- Optional (user chooses): Budget range, Timeline, Message
- Not shared: Saved properties, Search history, Payment info
- Agent sees inquiry history with this user
- User can choose to remain anonymous (Phase 2)

Deliverables:
- Contact information sharing logic
- Optional fields in contact form
- Agent view of inquiry history
- Privacy notice during contact

---

**Q53: Should we mask phone numbers to prevent off-platform contact?**
**A53:** Yes, with temporary masked numbers (Phase 2).
- MVP: Show actual numbers (simplicity)
- Phase 2: Implement masked/temporary numbers
- Each conversation gets unique virtual number
- Numbers expire after 30 days of inactivity
- Calls routed through platform for recording/audit
- Protects agent privacy and prevents platform bypass

Deliverables (Phase 2):
- Virtual phone number integration
- Call routing system
- Number expiration logic
- Call recording and audit (opt-in)

---

**Q54: How do we handle spam/inappropriate messages?**
**A54:** Multi-layer spam protection.
- Automated spam detection (keyword filtering)
- User reputation system (new users have limits)
- Report message button for recipients
- Moderator review queue for reported messages
- Automatic blocking after multiple reports
- Account suspension for repeat offenders

Deliverables:
- Spam detection filters
- Message reporting interface
- Moderation queue dashboard
- User reputation system
- Automated blocking rules

---

**Q55: Can users block specific agents or companies?**
**A55:** Yes, block functionality available.
- Block agent from profile or message thread
- Blocked agents cannot:
  - Send messages
  - See user's inquiries
  - View user's profile
- User can unblock anytime
- Block list in user settings
- Company-wide block (Phase 2)

Deliverables:
- Block/unblock functionality
- Block list management interface
- Permission checks for blocked users
- Notification of block (to blocked user)

---

**Q56: What's the response time expectation for agents?**
**A56:** SLAs with tracking and incentives.

| Response Time | Rating | Impact |
|---|---|---|
| < 1 hour | Excellent | Boost in search |
| < 4 hours | Good | Neutral |
| < 24 hours | Average | Neutral |
| > 24 hours | Poor | Lower in search |
| > 48 hours | Very Poor | Warning, potential suspension |

- Response time shown on agent profile
- Automated reminders to agents
- "Fast responder" badge for top performers
- Monthly response time reports for companies

Deliverables:
- Response time tracking system
- Automated reminder notifications
- Response time badge component
- Company response time reporting
- Search ranking impact based on response time

---

**Q57: Should we implement read receipts for messages?**
**A57:** Yes, optional for users.
- Read receipts show when message was viewed
- Users can disable read receipts in privacy settings
- "Sent" vs "Delivered" vs "Read" indicators
- Available for both customers and agents

Deliverables:
- Message status tracking
- Read receipt toggle in settings
- Visual indicators for message status
- Privacy-compliant implementation

---

**Q58: How do we handle communication after a property is sold/rented?**
**A58:** Auto-close with archival.
- When property status changes to Sold/Rented:
  - Conversation auto-archived after 30 days
  - Users can still view history (read-only)
  - New messages disabled
  - Option to "Contact agent about other properties"
- Agent can initiate new conversation about different property

Deliverables:
- Property status change triggers
- Conversation archival logic
- Read-only archive view
- "Contact about other properties" feature

---

**Q59: Can users save favorite agents?**
**A59:** Yes, "Favorite Agents" list.
- Save agent from profile or after conversation
- Favorited agents appear in profile section
- Quick contact from favorites list
- Agent notified when favorited
- See all listings from favorite agents
- Share favorite agents with friends/family

Deliverables:
- Favorite agent button
- Favorites list management
- Agent notification for new favorites
- Filter by favorite agents in search

---

**Q60: Should we implement video calls within the app?**
**A60:** Phase 2 feature.
- MVP: Text chat only
- Phase 2: In-app video calls
- Integrated WebRTC solution
- No download required (browser-based)
- Call recording option (with consent)
- Virtual property tours via video
- Screen sharing for document review

Deliverables (Phase 2):
- WebRTC video call integration
- Call scheduling system
- Recording with consent
- Screen sharing capability
- Call history and logs

---

### 2.4 Favorites & Saved Items

**Q61: How many favorites can a user save?**
**A61:** Unlimited favorites.
- No technical limit on saved properties
- Performance optimization with pagination
- Users can save unlimited properties
- Warning when approaching 100 (optional)
- Cleanup reminders for stale favorites

Deliverables:
- Unlimited favorites storage
- Paginated favorites list
- Performance optimization
- Cleanup reminders (optional)

---

**Q62: Should favorites sync across devices?**
**A62:** Yes, cloud-synced.
- Favorites saved to user account (not device)
- Syncs automatically across all devices
- Web, iOS, Android show same list
- Real-time updates when favorited on one device
- Offline queue with sync on reconnection

Deliverables:
- Cloud-based favorites storage
- Cross-device synchronization
- Real-time updates
- Offline support with sync

---

**Q63: Can users create multiple lists (e.g., "Houses to visit", "Apartments for consideration")?**
**A63:** Yes, custom collections (Phase 2).
- MVP: Single favorites list
- Phase 2: Multiple custom collections
- Users can create named lists (e.g., "To Visit", "Shortlist", "Investment")
- Add/remove properties from lists
- Share lists with others (view-only)
- Notes per property in lists

Deliverables (Phase 2):
- Custom collection creation
- Multi-list management
- List sharing functionality
- Per-property notes
- List export (CSV/PDF)

---

**Q64: What happens to favorites when a property is removed?**
**A64:** Soft delete with notification.
- Property removed from marketplace becomes "Unavailable" in favorites
- User sees: "This property is no longer available"
- Option to view similar properties
- Option to remove from favorites
- Agent contact option for alternatives
- Historical data preserved (photos, details)

Deliverables:
- Unavailable property state
- Similar property suggestions
- One-click removal from favorites
- Agent contact for alternatives

---

**Q65: Should we notify users when a favorited property price changes?**
**A65:** Yes, price alert notifications.
- Real-time notification when price changes
- Shows old price vs new price
- Percentage change indicator
- User can opt-out per property
- Daily digest option for multiple changes
- Price drop alerts (especially for buyers)

Deliverables:
- Price change detection system
- Push/email notification templates
- Per-property notification settings
- Price drop alert logic
- Notification history

---

**Q66: Can users share favorites with family/friends?**
**A66:** Yes, sharing functionality.
- Share individual property via link
- Share entire favorites list (view-only)
- Options: WhatsApp, Email, SMS, Copy link
- Recipient doesn't need account to view
- Link expires after 30 days (optional)
- Share tracking (who viewed, Phase 2)

Deliverables:
- Property share button
- Favorites list share feature
- Multiple sharing channels
- Public view for shared links
- Link expiration option

---

**Q67: How do we handle expired favorites?**
**A67:** Auto-cleanup with user notification.
- Favorites older than 12 months flagged as "stale"
- User notified: "Some favorites may be outdated"
- Option to review and clean up
- Auto-remove after 18 months with user consent
- Statistics: "You've had X favorites for over a year"

Deliverables:
- Stale favorite detection
- Cleanup notification system
- Bulk removal option
- Favorite age statistics

---

**Q68: Should we show similar properties to favorites?**
**A68:** Yes, recommendation engine.
- "Because you liked..." section on favorites page
- Based on: district, price range, property type
- Updated weekly
- Click tracking for algorithm improvement
- Option to "Show more like this"

Deliverables:
- Recommendation algorithm (basic)
- Similar properties carousel
- Click tracking
- Feedback mechanism ("Not interested")

---

**Q69: Can users add notes to saved properties?**
**A69:** Yes, private notes.
- Add private note to any saved property
- Notes visible only to user
- Rich text support (bold, lists, links)
- Character limit: 500
- Search notes (Phase 2)
- Export notes with favorites

Deliverables:
- Notes field per property
- Rich text editor
- Character counter
- Privacy (user-only visibility)

---

**Q70: How do we export favorites list?**
**A70:** Export to CSV/PDF.
- Export entire favorites list
- Formats: CSV (Excel), PDF
- Includes: Property details, price, agent contact, notes
- Email export or direct download
- Scheduled exports (weekly/monthly) Phase 2
- Maximum export size: 1000 properties

Deliverables:
- CSV export functionality
- PDF export with formatting
- Email delivery option
- Export history tracking
- Large export handling

---

### 2.5 Service Requests (Maintenance, etc.)

**Q71: Can users request multiple services in one request?**
**A71:** Yes, multi-service requests supported.
- Users can select multiple services in one request
- Examples: "Fix outlet AND leaking faucet"
- Each service can have different provider
- Combined checkout with total cost
- Separate scheduling per service
- Single payment for all (or split)

Deliverables:
- Multi-service selection interface
- Combined checkout flow
- Per-service provider assignment
- Consolidated payment
- Individual service tracking

---

**Q72: What's the minimum information required for a service request?**
**A72:** Required vs optional fields.

| Field | Required? | Notes |
|---|---|---|
| Service Category | Yes | Electrical, Plumbing, etc. |
| Specific Issue | Yes | From options or custom |
| Property Address | Yes | Selected from user's properties |
| Urgency Level | Yes | Emergency, Urgent, Standard |
| Description | Yes | Details of the issue |
| Photos | No | Highly recommended |
| Preferred Time | No | If not urgent |
| Access Instructions | No | Gate code, etc. |
| Budget | No | If user has limit |

Deliverables:
- Form with required field validation
- Optional field encouragement
- Photo upload (recommended)
- Progress saving (draft)

---

**Q73: How do we handle emergency requests vs. scheduled?**
**A73:** Priority routing with premium pricing.

| Urgency | Response Time | Pricing | Routing |
|---|---|---|---|
| Emergency | Within 2 hours | Premium (+50-100%) | Top priority, notify all available |
| Urgent | Within 24 hours | Standard +25% | High priority, next available |
| Standard | 3-5 days | Standard | Normal queue |
| Scheduled | User picks date | Discount (-15%) | Scheduled dispatch |

- Emergency requests trigger SMS/push to all eligible technicians
- User pays premium for immediate response
- Platform guarantees response time or refunds premium

Deliverables:
- Urgency selection with clear pricing
- Priority routing logic
- Emergency notification system
- Response time tracking
- SLA guarantees with refund logic

---

**Q74: Can users attach photos/videos to service requests?**
**A74:** Yes, essential for accurate quotes.
- Upload photos directly from camera/gallery
- Maximum 10 photos per request
- Video upload supported (max 30 seconds)
- Automatic compression
- Providers can request additional photos
- Photos stored with request permanently

Deliverables:
- Camera/gallery integration
- Multi-photo upload
- Video upload with compression
- Provider photo request system
- Photo gallery in request details

---

**Q75: How do we match service requests to available providers?**
**A75:** Multi-factor matching algorithm.

Matching Factors:
1. Distance - Proximity to property (primary)
2. Availability - Current capacity and schedule
3. Skills - Matching service category
4. Rating - Higher-rated providers prioritized
5. Response time - Historical speed
6. Pricing - Within user's budget (if specified)

Process:
1. System identifies eligible providers within radius
2. Sends request to top 3 based on matching score
3. First to accept gets the job
4. If no acceptance in 15 minutes, expand to next tier
5. User can manually select from list

Deliverables:
- Matching algorithm with configurable weights
- Provider eligibility filtering
- Request broadcast system
- Acceptance timeout logic
- Manual provider selection fallback

---

**Q76: What happens if no provider is available in the user's area?**
**A76:** Smart fallback options.
- Auto-expand search radius (5km > 10km > 20km)
- Suggest scheduled (non-urgent) appointment
- Notify user when provider becomes available
- Offer alternative service categories
- Platform-sourced provider (Salguri direct) for emergencies
- Compensation offer for inconvenience (discount on next service)

Deliverables:
- Radius expansion logic
- Availability notification system
- Alternative service suggestions
- Platform backup provider system
- Compensation workflow

---

**Q77: Can users cancel a service request after confirmation?**
**A77:** Yes, with cancellation policy.

| Cancellation Time | Refund | Penalty |
|---|---|---|
| > 24 hours before | 100% refund | None |
| 12-24 hours before | 75% refund | 25% fee |
| 2-12 hours before | 50% refund | 50% fee |
| < 2 hours before | 0% refund | 100% fee |
| After technician dispatched | 0% + trip fee | Trip fee charged |

- Emergency requests have stricter policy (2 hours = 50%)
- User acknowledges policy during booking
- Cancellation reason collected for analytics
- Dispute resolution available

Deliverables:
- Cancellation interface with timing
- Automated refund calculation
- Policy acknowledgment during booking
- Cancellation reason tracking
- Dispute initiation for special cases

---

**Q78: What's the cancellation policy and refund process?**
**A78:** Automated refunds with manual review option.
- Refunds processed automatically based on policy
- Refund to original payment method
- Mobile money refunds within 24-48 hours
- Card refunds 5-7 business days
- Partial refunds supported
- Manual override for support team

Deliverables:
- Automated refund processing
- Refund status tracking
- Manual override for support
- Refund notification system

---

## PART 10: UI/UX QUESTIONS

### 10.1 Design System
- Dark mode: Phase 2
- RTL language support (Arabic, Somali): Required from day one
- WCAG accessibility compliance: Level AA minimum
- Responsive design: Mobile-first approach
- Loading states: Skeleton screens for all content
- Error messages: User-friendly with actionable suggestions
- Empty states: Illustrated with CTAs
- Onboarding: 3-screen tutorial on first launch
- Form validation: Real-time inline validation
- Iconography: Consistent icon set (Material Design or custom)

### 10.2 Mobile-Specific UX
- Bottom sheet navigation for filters and actions
- Swipe gestures for navigation
- System back button behavior respected
- Pull-to-refresh on all list screens
- Infinite scrolling with loading indicators
- Tab navigation for main sections
- Search with autocomplete suggestions
- Native camera integration for photos
- Voice input for search (Phase 2)
- Offline mode indicators with sync status
