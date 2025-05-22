# Local Volunteer Connector

A decentralized platform built on Stacks blockchain that connects local volunteers with community service opportunities, featuring reputation tracking and secure volunteer management.

## 🚀 Features

### Phase 1 (Completed)
- ✅ Volunteer registration and profile management
- ✅ Opportunity creation and management
- ✅ Basic volunteer-opportunity matching

### Phase 2 (Current)
- ✅ **Enhanced Security**: Input validation, proper error handling, and access controls
- ✅ **Bug Fixes**: Fixed opportunity existence validation in close-opportunity function
- ✅ **Reputation System**: New contract for tracking volunteer and organization credibility
- ✅ **Application System**: Volunteers can now apply for opportunities with status tracking
- ✅ **Advanced Features**: Volunteer active/inactive status, skill matching, date validation

## 📋 Smart Contracts

### Main Contract (`main.clar`)
The core contract managing volunteers and opportunities with enhanced security features:

**Key Functions:**
- `register-volunteer`: Register as a volunteer with name, skills, and location
- `update-volunteer`: Update volunteer profile information
- `toggle-volunteer-status`: Activate/deactivate volunteer status
- `create-opportunity`: Create volunteer opportunities with required skills and date validation
- `apply-for-opportunity`: Apply for available opportunities
- `close-opportunity`: Mark opportunities as filled (with proper validation)
- `get-volunteer`: Retrieve volunteer information
- `get-opportunity`: Retrieve opportunity details

**Security Enhancements:**
- Input validation for all string inputs
- Date validation for future opportunities
- Proper error constants and handling
- Access control for sensitive operations
- Protection against duplicate applications

### Reputation Contract (`reputation.clar`)
A comprehensive reputation system tracking performance and credibility:

**Key Functions:**
- `review-volunteer`: Organizations can rate volunteer performance (1-5 scale)
- `review-organization`: Volunteers can rate organization experiences
- `record-no-show`: Track volunteer no-shows with reputation penalties
- `get-volunteer-reputation`: View volunteer reputation metrics
- `get-organization-reputation`: View organization reputation metrics

**Reputation Metrics:**
- Total reputation score
- Completed opportunities count
- No-show tracking
- Average ratings
- Review history with timestamps

## 🛠️ Development Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation
```bash
# Clone the repository
git clone <your-repo-url>
cd local-volunteer-connector

# Verify setup
clarinet check

# Run tests
clarinet test
```

### Project Structure
```
local-volunteer-connector/
├── contracts/
│   ├── main.clar          # Core volunteer/opportunity management
│   └── reputation.clar    # Reputation and review system
├── tests/
│   ├── main_test.ts       # Main contract tests
│   └── reputation_test.ts # Reputation contract tests
├── Clarinet.toml          # Project configuration
└── README.md             # This file
```

## 📊 Usage Examples

### For Volunteers
```clarity
;; Register as a volunteer
(contract-call? .main register-volunteer "Alice Smith" "Teaching, Mentoring" "Downtown")

;; Apply for an opportunity
(contract-call? .main apply-for-opportunity u1)

;; Check your reputation
(contract-call? .reputation get-volunteer-reputation tx-sender)
```

### For Organizations
```clarity
;; Create an opportunity
(contract-call? .main create-opportunity "Beach cleanup event" u150 "Environmental awareness")

;; Review a volunteer after completion
(contract-call? .reputation review-volunteer 'ST1... u1 u5 "Excellent volunteer, very reliable!")

;; Close a filled opportunity
(contract-call? .main close-opportunity u1)
```

## 🔒 Security Features

- **Input Validation**: All user inputs are validated for proper format and length
- **Access Controls**: Function-level permissions ensure only authorized users can perform actions
- **Anti-fraud Measures**: Prevention of self-reviews and duplicate applications
- **Date Validation**: Opportunities must be scheduled for future dates
- **Error Handling**: Comprehensive error codes and meaningful error messages

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
# Run all tests
clarinet test

# Check contract syntax
clarinet check

# Interactive testing
clarinet console
```

## 🗺️ Roadmap

### Phase 3 (Planned)
- [ ] Token rewards for completed volunteer work
- [ ] Advanced matching algorithms based on skills and location
- [ ] Multi-signature approval for high-impact opportunities
- [ ] Integration with external calendar systems
- [ ] Mobile-friendly web interface

### Phase 4 (Future)
- [ ] Cross-chain compatibility
- [ ] NFT certificates for volunteer achievements
- [ ] DAO governance for platform decisions
- [ ] Analytics dashboard for community impact

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

### Development Guidelines
- Follow Clarity best practices
- Write comprehensive tests for new features
- Update documentation for any API changes
- Ensure security considerations are addressed

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🆘 Support

If you encounter any issues or have questions:
1. Check existing [Issues](../../issues)
2. Create a new issue with detailed description
3. Join our community discussions

