---
name: brainstorm
description: Use before creative work or significant changes, to turn an idea into a validated design through conversation. Activates on "brainstorm", "let's brainstorm", "deep analysis", "analyze this feature", "think through", "help me design", "explore options for", or when the user asks for a thorough analysis of a change, feature, or architectural decision.
---

# Brainstorm

Turn an idea into a design the user has agreed to, before anyone writes code. The session is done when the user has validated each part of the design and picked a next step.

## 1. Understand the idea

Start with the context you can gather yourself: the relevant code, docs, and recent commits. Then ask about what you could not work out: the purpose, constraints, what success looks like, and where it plugs in. Ask in small rounds, one topic at a time; related questions can go together in one AskUserQuestion call. Offer multiple choice with a recommended answer where you can.

## 2. Explore approaches

Once the problem is clear, propose two or three approaches with their trade-offs, conversationally rather than as a formal document. Lead with the one you recommend and say why. When one approach is plainly right, say so rather than inventing alternatives.

Cut features the goal doesn't need. When code would repeat, name the trade-off: duplication is simpler and uncoupled, an abstraction is DRY but adds complexity. Recommend one, and let the user decide.

## 3. Present the design

Once the user has chosen an approach, present the design in sections of a few hundred words: architecture, components, data flow, error handling, and testing. After each section, check that it looks right. Going back is cheap now and expensive later, so revisit earlier sections when something new doesn't fit them.

## 4. Next step

Ask with AskUserQuestion:
- **Write plan**: run `/planning:plan-make`, passing the brainstorm's context (the files found, the chosen approach, the design decisions) so it does not ask again.
- **Plan mode**: use EnterPlanMode to plan with the user's approval.
- **Start now**: implement directly, when the design is small enough. Track the tasks in a task list and mark each one done as it lands.
