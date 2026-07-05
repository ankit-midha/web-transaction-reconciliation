#!/usr/bin/env python3
"""
E2E simulation of the intake phase for WTR-5.
Mimics what Claude Code does when processing the intake prompt.
"""

import json
import time
import sys
from pathlib import Path
from datetime import datetime

class IntakeSimulator:
    """Simulates Claude's intake phase processing"""

    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.ticket_path = repo_root / ".workflow" / "ticket.json"
        self.spec_path = repo_root / ".workflow" / "artifacts" / "spec.md"
        self.prompt_path = repo_root / "prompts" / "intake.md"
        self.metrics = {
            "start_time": None,
            "end_time": None,
            "duration_ms": None,
            "ticket_size_bytes": 0,
            "prompt_size_bytes": 0,
            "spec_size_bytes": 0,
            "sections_generated": 0,
            "open_questions_count": 0,
            "acceptance_criteria_count": 0,
        }

    def extract_adf_text(self, content_node):
        """Extract plain text from Atlassian Document Format"""
        texts = []

        if isinstance(content_node, dict):
            if content_node.get("type") == "text":
                texts.append(content_node.get("text", ""))
            if "content" in content_node:
                for child in content_node["content"]:
                    texts.extend(self.extract_adf_text(child))

        elif isinstance(content_node, list):
            for item in content_node:
                texts.extend(self.extract_adf_text(item))

        return texts

    def parse_ticket(self):
        """Parse the Jira ticket JSON"""
        print("[1/4] Reading ticket.json...")
        with open(self.ticket_path) as f:
            ticket = json.load(f)

        self.metrics["ticket_size_bytes"] = self.ticket_path.stat().st_size

        # Extract key fields
        key = ticket.get("key")
        fields = ticket.get("fields", {})
        summary = fields.get("summary", "")
        issue_type = fields.get("issuetype", {}).get("name", "Unknown")
        reporter_email = fields.get("reporter", {}).get("emailAddress", "unknown@example.com")

        # Extract description text from ADF
        description_adf = fields.get("description", {})
        description_texts = self.extract_adf_text(description_adf)
        description = "\n".join(description_texts)

        print(f"  ✓ Parsed {key}: {summary}")
        print(f"    Type: {issue_type}")
        print(f"    Description: {len(description)} chars")

        return {
            "key": key,
            "summary": summary,
            "issue_type": issue_type,
            "reporter_email": reporter_email,
            "description": description,
            "fields": fields
        }

    def generate_spec(self, ticket_data):
        """Generate the spec.md file based on ticket data"""
        print("[2/4] Generating spec.md...")

        # Parse description sections
        description = ticket_data["description"]
        sections = {
            "background": "",
            "objective": "",
            "acceptance_criteria": [],
            "technical_notes": [],
            "out_of_scope": []
        }

        # Simple section extraction (in real Claude, this would be NLP)
        current_section = None
        for line in description.split("\n"):
            line_lower = line.lower().strip()
            if "background" in line_lower and line.startswith("##"):
                current_section = "background"
            elif "objective" in line_lower and line.startswith("##"):
                current_section = "objective"
            elif "acceptance criteria" in line_lower and line.startswith("##"):
                current_section = "acceptance_criteria"
            elif "technical note" in line_lower and line.startswith("##"):
                current_section = "technical_notes"
            elif "out of scope" in line_lower and line.startswith("##"):
                current_section = "out_of_scope"
            elif current_section and line.strip():
                if current_section in ["acceptance_criteria", "technical_notes", "out_of_scope"]:
                    if line.strip().startswith(("-", "*", "1.", "2.", "3.", "4.", "5.")):
                        sections[current_section].append(line.strip())
                else:
                    sections[current_section] += line + "\n"

        # Count metrics
        self.metrics["acceptance_criteria_count"] = len(sections["acceptance_criteria"])

        # Generate open questions (simulated)
        open_questions = [
            "Should the reconciliation process handle refunds and chargebacks, or only completed transactions?",
            "What is the expected behavior when settlement files arrive late (after business hours)?",
            "Are there any data retention or PCI compliance requirements beyond the 7-year storage?",
            "Should the system support manual re-runs for specific date ranges?"
        ]
        self.metrics["open_questions_count"] = len(open_questions)

        # Build spec content
        spec_content = f"""# Draft spec — {ticket_data['key']}: {ticket_data['summary']}

## Problem
Our payment gateway integration lacks automated reconciliation between our transaction database and daily settlement reports from payment processors (Stripe, PayPal). This causes:

- Undetected failed transactions appearing as successful
- Duplicate charges discovered only via customer complaints
- Revenue discrepancies between financial reports and bank deposits
- 4-6 hours daily manual reconciliation by finance team

## Goal
Build an automated reconciliation system that ingests daily settlement files, matches transactions against our database, identifies discrepancies, and generates exception reports with alerts when thresholds are exceeded.

## Non-Goals
- Automatic correction of discrepancies (manual review required)
- Real-time reconciliation (daily batch is sufficient for initial phase)
- Additional payment gateway integrations beyond Stripe and PayPal

## Users / Surfaces affected
**Finance team** — primary users consuming daily reconciliation reports and exception alerts

**Technical surfaces:**
- New reconciliation service (Lambda + Step Functions)
- S3 bucket integration for settlement file ingestion
- PostgreSQL transactions table queries (20M rows)
- PDF report generation
- Email notification system

## Acceptance Criteria
"""
        for criterion in sections["acceptance_criteria"]:
            spec_content += f"{criterion}\n"

        spec_content += f"""
## Open Questions
"""
        for i, question in enumerate(open_questions, 1):
            spec_content += f"{i}. {question}\n"

        spec_content += f"""
## Out-of-Scope
- Integration with accounting system (QuickBooks export) — deferred to future iteration
- Chargeback/dispute tracking — separate project WTR-12
- Additional gateway integrations (Adyen, Square) — Phase 2
- UI dashboard for historical reconciliation analysis

---
_Reply on this ticket to refine. When you're happy, comment `APPROVED` (uppercase, standalone) and the workflow will move to the Plan phase._
_Job: {ticket_data.get("job_id", "unknown")} · Ref: {ticket_data.get("client_ref", "unknown")}_
"""

        self.metrics["sections_generated"] = 7  # Problem, Goal, Non-Goals, Users, Acceptance, Questions, Out-of-Scope

        # Write spec file
        self.spec_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.spec_path, "w") as f:
            f.write(spec_content)

        self.metrics["spec_size_bytes"] = self.spec_path.stat().st_size
        print(f"  ✓ Generated spec: {self.metrics['spec_size_bytes']} bytes")
        print(f"    Sections: {self.metrics['sections_generated']}")
        print(f"    Open questions: {self.metrics['open_questions_count']}")
        print(f"    Acceptance criteria: {self.metrics['acceptance_criteria_count']}")

    def validate_output(self):
        """Validate the generated spec meets requirements"""
        print("[3/4] Validating output...")

        if not self.spec_path.exists():
            print("  ✗ spec.md was not generated")
            return False

        with open(self.spec_path) as f:
            content = f.read()

        # Check required sections
        required_sections = [
            "# Draft spec",
            "## Problem",
            "## Goal",
            "## Non-Goals",
            "## Users / Surfaces affected",
            "## Acceptance Criteria",
            "## Open Questions",
            "## Out-of-Scope"
        ]

        missing = []
        for section in required_sections:
            if section not in content:
                missing.append(section)

        if missing:
            print(f"  ✗ Missing sections: {missing}")
            return False

        print("  ✓ All required sections present")
        return True

    def run(self):
        """Execute the full intake simulation"""
        print("=" * 60)
        print("E2E Intake Phase Simulation - WTR-5")
        print("=" * 60)

        self.metrics["start_time"] = datetime.now().isoformat()
        start_ms = time.time() * 1000

        try:
            # Step 1: Parse ticket
            ticket_data = self.parse_ticket()

            # Add env vars to ticket data
            import os
            ticket_data["job_id"] = os.environ.get("JOB_ID", "unknown")
            ticket_data["client_ref"] = os.environ.get("CLIENT_REF", "unknown")

            # Step 2: Generate spec
            self.generate_spec(ticket_data)

            # Step 3: Validate
            valid = self.validate_output()

            # Calculate duration
            end_ms = time.time() * 1000
            self.metrics["end_time"] = datetime.now().isoformat()
            self.metrics["duration_ms"] = int(end_ms - start_ms)

            print("[4/4] Simulation complete")
            print()

            return valid

        except Exception as e:
            print(f"✗ Simulation failed: {e}")
            import traceback
            traceback.print_exc()
            return False

    def get_metrics(self):
        """Return collected metrics"""
        return self.metrics


def main():
    repo_root = Path(__file__).parent.parent.parent
    simulator = IntakeSimulator(repo_root)

    success = simulator.run()
    metrics = simulator.get_metrics()

    # Print summary
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"Status: {'SUCCESS' if success else 'FAILED'}")
    print(f"Duration: {metrics['duration_ms']}ms")
    print(f"Ticket size: {metrics['ticket_size_bytes']} bytes")
    print(f"Spec size: {metrics['spec_size_bytes']} bytes")
    print(f"Sections: {metrics['sections_generated']}")
    print(f"Open questions: {metrics['open_questions_count']}")
    print(f"Acceptance criteria: {metrics['acceptance_criteria_count']}")
    print("=" * 60)

    # Save metrics
    metrics_file = repo_root / ".workflow" / "artifacts" / "e2e-results" / f"metrics_{int(time.time())}.json"
    metrics_file.parent.mkdir(parents=True, exist_ok=True)
    with open(metrics_file, "w") as f:
        json.dump(metrics, f, indent=2)
    print(f"\nMetrics saved to: {metrics_file}")

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
