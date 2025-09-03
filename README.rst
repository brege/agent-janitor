===========
llm-janitor
===========

These scripts are for cleaning up agentic litter from ``~/``.

There are two modes: ``cache`` cleans up all history and cache detritus left behind by these tools.
The ``all`` mode purges the system of auth tokens, ``AGENTS.md``, ``CLAUDE.md``, and installations.

- claude_

- codex_

- codeium_ (now called ``windsurf``)

.. _claude: https://github.com/anthropics/claude-code

.. _codex: https://github.com/openai/codex/

.. _codeium: https://github.com/Exafunction/windsurf.nvim

What gets removed
-----------------

Here's what's removed in **cache** mode:

- Claude

  - ``**/.claude/`` project folders  
  - ``**/CLAUDE.md`` breadcrumbs  
  - ``/tmp/claude-*`` scratchpads  
  - ``~/.claude/{projects,file-history,debug,session-env,shell-snapshots,statsig,todos}``  
  - ``~/.claude/history.jsonl`` and ``~/.claude/settings.json``  

- Codex

  - ``~/.codex/sessions``
  - ``~/.codex/log``
  - ``~/.codex/history.jsonl``

- Codeium

  - ``~/.codeium/code_tracker/active``
  - ``~/.codeium/code_tracker/history``
  - ``~/.codeium/context_state``
  - ``~/.codeium/database``

Here's what's removed in **all** mode:

- Claude: cache targets plus

  - ``~/.claude``
  - ``~/.claude.json*``
  - ``~/.local/lib/node_modules/@anthropic-ai/claude-code``

- Codex: cache targets plus

  - ``~/.codex`` (auth/config/version)
  - ``~/.codex.json*``
  - ``~/.npm-global/lib/node_modules/@openai/codex``
  - ``AGENTS.md`` & ``AGENTS.override.md`` along the scanned path

- Codeium: cache targets plus

  - entire ``~/.codeium`` tree
