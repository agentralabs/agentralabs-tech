---
status: stable
---

# Playbooks: Agent Integration

This document provides step-by-step playbooks for integrating AgenticCognition into agent workflows.

## Playbook 1: Personal Assistant Agent

Connect cognition to a personal assistant to provide responses calibrated to the user's belief system, decision patterns, and growth trajectory. The agent calls `cognition_model_heartbeat` on each interaction and `cognition_predict` before giving advice.

## Playbook 2: Coaching Agent

Use shadow psychology and drift tracking to build a coaching agent that surfaces blindspots, tracks growth over time, and provides personalized guidance based on self-concept topology.

## Playbook 3: Decision Support Agent

Combine decision simulation with belief graph analysis to help users make better decisions. The agent runs `cognition_simulate` with options and explains how each choice aligns with or contradicts the user's core values.

## Playbook 4: Multi-Agent Ecosystem

In a multi-agent setup, AgenticCognition serves as the shared understanding layer. Each agent reads from the same `.acog` file, ensuring consistent user modeling across all interactions.

## Playbook 5: Team Context Agent

Use per-project `.acog` files to maintain separate user models for different work contexts. The agent automatically loads the correct model based on the active project directory.
