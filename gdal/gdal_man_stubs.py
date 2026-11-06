"""Minimal Sphinx extension standing in for unpackaged third-party ones.

sphinx-tabs, sphinx-toolbox and sphinxcontrib-spelling are not packaged,
and GDAL's man pages use their tabs, tab, code-tab, collapse and
spelling:word-list directives.
"""

from docutils import nodes
from docutils.parsers.rst import Directive, directives
from sphinx.util.docutils import SphinxDirective


class Container(SphinxDirective):
    has_content = True
    optional_arguments = 1
    final_argument_whitespace = True
    option_spec = {"class": directives.unchanged}

    def run(self):
        node = nodes.container()
        self.state.nested_parse(self.content, self.content_offset, node)
        return [node]


class CodeTab(SphinxDirective):
    has_content = True
    optional_arguments = 2
    final_argument_whitespace = True
    option_spec = {"class": directives.unchanged}

    def run(self):
        node = nodes.literal_block("\n".join(self.content), "\n".join(self.content))
        if self.arguments:
            node["language"] = self.arguments[0].split()[0]
        return [node]


class Ignore(Directive):
    has_content = True
    optional_arguments = 100
    final_argument_whitespace = True
    option_spec = None

    def run(self):
        return []


def setup(app):
    app.add_directive("tabs", Container)
    app.add_directive("tab", Container)
    app.add_directive("collapse", Container)
    app.add_directive("code-tab", CodeTab)
    app.add_directive("spelling:word-list", Ignore)
    return {"parallel_read_safe": True, "parallel_write_safe": True}
