# Accordion Panels for Quarto Websites


Easily add Bootstrap accordion panels to your Quarto websites using this
extension.

When used with `format: html`, the content is rendered as a Bootstrap
accordion component. In other formats, the content is rendered as normal
Quarto markdown.

## Installing

``` bash
quarto add gadenbuie/quarto-panel-accordion
```

This will install the extension under the `_extensions` subdirectory. If
you’re using version control, you will want to check in this directory.

To use the extension, you need to add it to your Quarto project YAML
metadata:

``` yaml
filters:
  - panel-accordion
```

## Using

Creating an accordion panel is similar to creating a [tabset
panel](https://quarto.org/docs/output-formats/html-basics.html#tabsets).
Wrap the accordion content in a `panel-accordion` block.

``` markdown
::: {.panel-accordion}
### Accordion 1

First accordion content

### Accordion 2

Second accordion content
:::
```

You can allow multiple panels to be open at once by adding
`multiple="true"` to the block:

``` markdown
::: {.panel-accordion multiple="true"}

:::
```

And you can choose which panel is open initially by adding an `.open`
class to the accordion panel header:

``` markdown
::: {.panel-accordion}
### Accordion 1

First accordion content

### Accordion 2 {.open}

Second accordion content
:::
```

Finally, you can include custom icons for the accordion panel with the
`icon` attribute, which accepts either the name of the icon from
[Boostrap Icons](https://icons.getbootstrap.com/) or a custom HTML icon
element.

``` markdown
::: {.panel-accordion}
### Accordion 1 {.open icon="1-square-fill"}
First accordion content

### Accordion 2 {icon="2-square-fill"}
Second accordion content
:::
```

## Acknowledgements

For another approach to creating accordion panels, see the [accordion
extension by Roy
Francis](https://github.com/royfrancis/quarto-accordion).
