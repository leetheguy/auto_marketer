Project Journal & Status Report
This document serves as the single source of truth for the Auto Marketer project, outlining its vision, architecture, implementation, and history.

1. The 30,000 Foot View: The Vision
Project Codename: The Genesis Prototool

Short-Term Goal (The Shuttle): To build a highly-efficient "human-in-the-loop" application, currently named Auto Marketer. This app serves as a thin client for an agentic AI marketing workflow. Its primary purpose is to allow a human user (Lee) to efficiently review, edit, approve, and manage content that is generated and processed by a series of AI agents.

Long-Term Vision (The Starship): To evolve the application into a true Genesis Prototool client. The ultimate goal is for the app to be a universal application constructor. It will receive a "Genesis Packet" (a JSON object) from a secure bootstrap transmission, which will then dynamically construct the entire user interface, data schemas, and operational logic on the fly. This would enable an AI to generate and deploy bespoke applications from a single prompt.

2. The 10,000 Foot View: The Strategy
The Thin Client Model: The Flutter application contains minimal business logic. Its primary role is to be a reactive view layer that displays data and sends user actions to the backend.

Clear Separation of Concerns:

Logic & Actions (The Brain): Handled exclusively by n8n workflows.

Data & State (The Memory): Stored and managed in a Supabase (PostgreSQL) database.

The Two-Question Test: Every major architectural decision is weighed against two factors:

Does this get us closer to shipping a great text editor now?

Does this path make it easier or harder to get to the Genesis Prototool later?

The Genesis Packet Principle: The app's entire operational structure (types, states, actions, navigation) is defined by a single, self-contained JSON document. The app reads this "Genesis Packet" and builds its UI and logic accordingly.

3. The Ground-Level View: The Implementation
Technology Stack:

Frontend: Flutter

State Management: flutter_riverpod

Backend Logic: Self-hosted n8n instance

Backend Data: Supabase (PostgreSQL)

Database Schema (The Genesis Model):

accounts table: Allows for multi-tenancy of different workflows.

workflows table: The core of the new architecture. Contains a definition column (JSONB) that holds the entire "Genesis Packet" for a given account.

content_items table: A single, master table for all content. It uses type_name and state_name fields (defined by the workflow JSON) and a self-referencing parent_id to create a hierarchical structure.

content_versions table: Stores the version history and author_signature for each content_item.

Application Structure:

Configuration: Secrets are managed via a .env file; URLs and app behavior are centralized in config.dart.

Central WorkflowProvider: The new "brain" of the app. A single provider that fetches, parses, and provides the active workflow JSON to the entire application.

Dependent Providers: All other providers (listProvider, actionsProvider, etc.) are now simple "selectors" that read their data from the central workflowProvider, ensuring a single source of truth.

Dynamic UI Components:

HomeScreen: A fully dynamic screen that builds its navigation grid based on the types defined in the active workflow. Includes an account selection dropdown and a "New Idea" button.

ListScreen: A generic, hierarchical screen that can display either top-level content or the children of a specific project.

EditorScreen: A "smart container" that dynamically displays different editor widgets (e.g., MarkdownEditor, ImageEditor) based on the content's type, as defined in the workflow.

4. Project Journal: The Journey So Far
POC Phase: Validated the basic Flutter -> n8n -> Supabase data flow with a simple "notes" app.

Vision Clarification: Established the "Genesis Prototool" as the long-term vision, prompting a major strategic pivot.

Relational Model: Built a robust, normalized database schema with separate tables for types, states, actions, etc.

Feature Implementation (Relational): Built a dynamic HomeScreen, generic ListScreen, and a powerful, responsive EditorScreen with real-time saving and dynamic action buttons based on the relational model.

The Genesis Leap (Major Refactor): Made the strategic decision to abandon the complex relational model in favor of a simpler, more powerful document-based approach.

Consolidated the entire workflow definition (types, states, actions, rules) into a single, nested JSON object (the "Genesis Packet").

Simplified the database schema to a few core tables, with the new workflows table at its heart.

Refactored the entire Flutter application to be driven by a central WorkflowProvider, making the UI almost completely dynamic and defined by the backend JSON.

Multi-Modal Editor: Refactored the EditorScreen into a "smart container" capable of displaying different editor widgets based on the content's type. Extracted the Markdown editor into its own "dumb" component.

Real-Time Lists: Converted the listProvider from a FutureProvider to a StreamProvider to ensure lists update in real-time when data changes in Supabase.

Bug Squashing: Resolved a complex state management and timing bug related to populating the MarkdownEditor with its initial data.