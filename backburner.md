Project Roadmap: Backburnered Tasks & Future Features
This document tracks all major features, architectural upgrades, and polish items that have been deferred for future development.

Tier 1: Core User-Facing Features
These are the next major features that directly impact the user's workflow.

List View Enhancements:

Implement robust search, sort, and filtering capabilities for all list views.

Add a UI toggle to show/hide items marked as archived.

"Magic Wand" Contextual Menu:

When text is selected in the editor, a menu appears.

Section 1: AI Actions: A list of predefined AI touch-up options (e.g., "Add Emotion," "Check Facts").

Section 2: Custom AI Prompt: A text field allowing the user to enter a custom instruction for the selected text.

Section 3: Markdown Formatting: Quick buttons to apply Markdown syntax (bold, italics, highlights ==text==).

Dynamic Metadata Editor:

Add a button in the editor to view/edit the metadata JSONB field for a content item.

Dynamically generate form elements from a predefined template for inline editing.

Use a package like json_editor to build the user-friendly interface.

"System Working" State:

When an AI agent is processing a content item, its state should change to "System Working."

In the editor, this state should make the text fields read-only to prevent conflicts.

Display a small, unobtrusive loading indicator (e.g., a spinner next to the state name) to provide visual feedback.

Push Notifications:

Implement Firebase Cloud Messaging (FCM).

Allow n8n agents to send proactive notifications to the app (e.g., "Urgent news item found," "Task ready for review").

Notifications should deep-link to the relevant content item in the app.

Persona Chat Screen:

Create a dedicated chat interface for testing and interacting with different AI personas.

(This could potentially evolve into a separate, standalone application).

Tier 2: Major Architectural & System Upgrades
These are larger, foundational projects that will make the app more robust and scalable.

Multi-Editor Support:

The app will dynamically display the correct editor widget (markdown, image, json, etc.) based on the editor_type defined in the workflow JSON.

Full User Authentication:

Implement a complete sign-up and login flow using Supabase Auth.

Update all database RLS policies to be user-specific.

Migrate all existing content from the placeholder UUID to a real user ID.

In-App Workflow Management Tools:

Build a dedicated admin section in the app.

Create a UI to visually edit the workflow JSON.

Implement drag-and-drop reordering for types.

Centralized Webhook Service:

Refactor all n8n webhook calls out of the UI screens and into a single, dedicated service/controller.

Tier 3: UI/UX Polish & Refinements
These are smaller, high-impact improvements to the user experience.

Dynamic Theming & White-Labeling:

Define a comprehensive ThemeData object in main.dart.

Create a system to dynamically load theme data (colors, fonts, etc.) and a custom logo from a configuration source, allowing clients to brand the app.

Scroll-Syncing:

Implement percentage-based scroll-syncing between the editor and the Markdown preview pane.

Accordion Project Navigation:

In the ListScreen, add an accordion-style expander to "Project" items to show child content inline.