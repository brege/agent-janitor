===========
llm-janitor
===========

This script is for cleaning up agentic litter scattered across ``~/``.

There are two modes: ``cache`` cleans up all history and cache detritus left behind by these tools.
The ``all`` mode purges the system of auth tokens, ``AGENTS.md``, ``CLAUDE.md``, and installations.

- claude_

- codex_

- codeium_ (windsurf)

.. _claude: https://github.com/anthropics/claude-code

.. _codex: https://github.com/openai/codex/

.. _codeium: https://github.com/Exafunction/windsurf.nvim


Usage
-----

.. code-block:: bash

    llm-janitor cache [--agent NAME] [--level N] [--dry-run|--confirm] [BASEDIR]
    llm-janitor breadcrumbs [same flags]
    llm-janitor system   # level 30+
    llm-janitor all      # level 40+

The levels.

**cache**
  ``llm-janitor cache`` cleans up level ≤10 targets
    - Claude scratchpads
    - Codex history
    - Codeium history

**breadcrumbs**
  ``llm-janitor breadcrumbs`` cleans up level ≤20 entries and
    - local ``.claude`` dirs
    - local ``CLAUDE.md`` 
    - local ``AGENTS.md``

**system / all**
  ``llm-janitor system`` cleans up **all** level ≤30 entries and
    - auth tokens, settings, everything
    - ``~/.claude/``
    - ``~/.codex/``
    - ``~/.codeium/``

Alternatively, use ``--level N`` to delete Level-N or lower.

Use ``--agent NAME`` to delete only a specific agent's detritus.

By default, the script only lists the candidate removals. Use ``--confirm`` to actually remove files.


Configuration
-------------

See `janitor.default`_ for defaults.

.. _`janitor.default`: https://github.com/brege/llm-janitor/blob/main/janitor.default

How it works
''''''''''''

The lookup order starts with ``janitor.default``. To override or append, create a ``janitor.manifest`` in this project directory or create:

.. code-block:: bash

   ~/.config/llm-janitor/janitor.manifest

The syntax mirrors ``.gitignore`` syntax, with some extra dimensions to control agent and removal level.

.. code-block:: text

    # comment
    level=10 agent=claude cache: ~/.claude/projects/
    level=20 agent=claude breadcrumbs: ~/.claude/

    # don't remove agent breadcrumbs in ~/code/
    level=20 agent=claude breadcrumbs: ! ~/code/**CLAUDE*.md
    level=20 agent=claude breadcrumbs: ! ~/code/**settings*.json
    level=30 agent=codex breadcrumbs: ! ~/code/**AGENTS.md


