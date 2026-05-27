# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------

project = 'CryoGrid_Optimization_Automatization'
copyright = '2025, Fribault'
author = 'Fribault Tristan'
contact = 'fribaulttristan@gmail.com'
release = '1.0'

# -- General configuration ---------------------------------------------------

extensions = [
    "myst_parser",          # Support Markdown
    "sphinx_rtd_theme",     # Thème Read the Docs
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

language = 'en'

# Support both .md and .rst
source_suffix = {
    '.rst': 'restructuredtext',
    '.md': 'markdown',
}

# -- Options for HTML output -------------------------------------------------

html_theme = "sphinx_rtd_theme"
html_static_path = ['_static']

# -- MyST Parser Config ------------------------------------------------------

# Permet d'utiliser des extensions avancées Markdown (tableaux, figures, etc.)
myst_enable_extensions = [
    "colon_fence",     # ::: pour créer des blocs
    "deflist",         # Listes de définitions
    "html_admonition", # Notes / Tips / Warning stylés
    "html_image",      # Images faciles à intégrer
    "replacements",    # Remplacements automatiques
    "smartquotes",     # Guillemets typographiques
    "substitution",    # Substitutions
]

# Permet d'utiliser des titres avec ancre automatique
myst_heading_anchors = 3

