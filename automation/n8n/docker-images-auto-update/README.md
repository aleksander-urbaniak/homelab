# 🛠️ Docker Images Auto Update

This folder documents an n8n workflow that reviews Renovate/GitLab merge requests for Docker image updates and decides whether they can be merged automatically.

The public documentation describes the workflow behavior only. Private webhook IDs, GitLab hostnames, Discord guild/channel IDs, credential IDs, model credentials, and n8n instance metadata are intentionally omitted.

## Purpose

The workflow is designed to reduce manual work around routine Docker image updates while still keeping a review gate for risky changes.

It handles merge requests created by Renovate or a similar dependency-update bot, asks an AI agent to assess the update, comments the assessment back on the merge request, and either merges the update automatically or asks for manual approval.

## Trigger

The workflow starts from an n8n webhook that receives GitLab merge request events.

The initial filter requires:

- the merge request action to be `open`
- the merge request label to be `update`

Events that do not match those requirements are ignored.

## Assessment Flow

The AI assessment receives merge request context from the webhook payload:

- merge request URL
- title
- author
- description
- target branch

The prompt asks the AI agent to:

- confirm the update label
- identify the dependency or Docker image being updated
- classify the version change as patch, minor, or major where possible
- look for breaking changes in the description or changelog context
- evaluate the impact on the project deployment/configuration
- assign a risk level of `LOW`, `MEDIUM`, or `HIGH`
- choose one of `APPROVED`, `NEEDS REVIEW`, or `REJECTED`

The workflow uses a structured output parser so later nodes can route based on a predictable JSON response.

## Decision Rules

The expected AI response contains these fields:

```json
{
  "decision": "APPROVED",
  "assessment": "...",
  "changes": "...",
  "breaking": "...",
  "impact": "...",
  "risk": "...",
  "recommendation": "..."
}
```

The workflow then posts the assessment sections as a comment on the merge request.

## Auto-Merge Path

If the decision is `APPROVED`, the workflow:

- sets merge options
- squashes commits
- removes the source branch
- merges the merge request through the GitLab API
- waits briefly for the pipeline to start
- checks the resulting merge commit and pipeline status
- sends a success message if the pipeline succeeds

If the pipeline is still running, pending, or newly created, the workflow loops back and checks again.

If the pipeline fails or reaches a non-success terminal state, it sends a failure notification for manual follow-up.

## Manual Review Path

If the decision is `NEEDS REVIEW`, the workflow sends a Discord approval request and waits for a human decision.

If approved, the workflow continues into the same merge path used for automatically approved updates.

If declined, the workflow stops without merging.

## Error Handling

The AI agent path includes handling for model/provider failures such as:

- temporary service unavailability
- quota exhaustion
- high model demand

When that happens, the workflow sends a failure notification and leaves the merge request for manual review.

## Risk Model

The workflow treats routine service image updates as acceptable when the assessed impact is low.

The prompt is intentionally stricter for risky cases:

- database application updates are always considered high risk
- major version bumps generally require stronger justification
- breaking changes require review unless they clearly do not affect the current configuration
- service restarts and minor non-breaking changes can be accepted automatically

## External Integrations

The workflow uses:

- GitLab webhook events
- GitLab API for merge request comments and merging
- an AI chat model through n8n LangChain nodes
- Discord messages for manual approval and status notifications
- GitLab pipeline status checks after merge

## Redaction Notes

Do not commit exported workflow JSON without redacting:

- webhook paths and IDs
- GitLab domain and project IDs if private
- credential IDs and credential names
- Discord guild/channel IDs
- n8n instance ID
- AI provider credential IDs
- private URLs in notification templates

Use placeholders such as `gitlab.example.com`, `discord-channel-id`, `credential-id`, and `webhook-id` in public examples.
