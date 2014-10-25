# CSS/Sass Coding Guidelines

Protected Planet is styled with [Sass](http://sass-lang.com) compiled to CSS. We have a few strict coding guidelines you must stick to when adding or modifying any Sass to the project.

#### Acknowledgements

These guidelines are adapted from the [Medium](http://medium.com) LESS [coding guidelines](https://gist.github.com/fat/a47b882eb5f84293c4ed).

## Contents

1. [Naming Conventions](#naming-conventions)
	1. Namespacing
	2. Javascript
2. IDs vs. Classes
3. Formatting
	1. Nesting
	2. Comments
	3. Spacing
	4. Quotes
4. Polyfills and Vendor Prefixes
5. Variables
	1. Colours
	2. z-index
6. Components
7. Semantics
	1. Grids
8. Performance
	1. Specificity
9. Clearfixes

## Naming Conventions

Classes and IDs are lowercase with words separated by a dash:

**Right:**

```css
.user-profile {}
.post-header {}
#top-navigation {}
```

**Wrong:**

```css
.userProfile {}
.postheader {}
#top_navigation {}
```

Image file names are lowercase with words separated by a dash:

**Right:**
```
icon-home.png
```

**Wrong:**
```
iconHome.png
icon_home.png
iconhome.png
```

Image file names are prefixed with their usage.

**Right:**

```
icon-home.png
bg-container.jpg
bg-home.jpg
sprite-top-navigation.png
```

**Wrong:**

```
home-icon.png
container-background.jpg
bg.jpg
top-navigation.png
```

### Namespacing

Namespacing is great! But it should be done at a component level – never at a page level.

Also, namespacing should be made at a descriptive, functional level. Not at a page location level. For example, .profile-header could become .header-hero-unit.

**Right:**

```css
.nav,
.nav-bar,
.nav-list
```

**Wrong:**

```css
.nav,
.home-nav,
.profile-nav,
```

### Javascript

syntax: `js-<targetName>`

JavaScript-specific classes reduce the risk that changing the structure or theme of components will inadvertently affect any required JavaScript behaviour and complex functionality. It is not neccesarry to use them in every case, just think of them as a tool in your utility belt. If you are creating a class, which you dont intend to use for styling, but instead only as a selector in JavaScript, you should probably be adding the `js-` prefix. In practice this looks like this:

```html
<a href="/login" class="btn btn-primary js-login"></a>
```

**Again, JavaScript-specific classes should not, under any circumstances, be styled.**

## IDs vs. Classes

You should almost never need to use IDs.

## Formatting

The following are some high level page formatting style rules.

### Nesting

Sass nesting can be incredibly powerful, but can also hinder your ability to quickly determine what a style is applying to and wether or not you can optimise your selectors.

**Wrong**:

```css
.list-btn {
  .list-btn-inner {
    .btn {
      background: red;
    }
    .btn:hover {
      .opacity(.4);
    }
  }
}
```

### Comments

Eschew CSS `/* .. */` block comments in favour of Sass `// ...` inline comments as these are not included in the compiled source.

### Spacing

CSS rules should be comma seperated but live on new lines:

**Right:**

```css
.content,
.content-edit {
  ...
}
```

**Wrong:**

```css
.content, .content-edit {
  ...
}
```

CSS blocks should be seperated by a single blank line.

**Right**:

```css
.content {
  ...
}

.content-edit {
  ...
}
```

**Wrong**:

```css
.content {
  ...
}
.content-edit {
  ...
}
```

### Quotes

Quotes are optional in CSS and Sass. We use double quotes as it is visually clearer that the string is not a selector or a style property.

**Right:**

```css
background-image: url("/img/you.jpg");
font-family: "Helvetica Neue Light", "Helvetica Neue", Helvetica, Arial;
```

**Wrong:**

```css
background-image: url(/img/you.jpg);
font-family: Helvetica Neue Light, Helvetica Neue, Helvetica, Arial;
```

## Polyfills and Vendor Prefixes

We use [autoprefixer](https://github.com/postcss/autoprefixer) to automatically generate CSS with vendor prefixes added, therefore you can use modern CSS and it will be polyfilled for you.

**Right:**

```css
.thing  {
  border-radius: 10px;
}
```

**Wrong:**

```css
.thing  {
  -webkit-border-radius: 10px;
  -moz-border-radius: 10px;
  border-radius: 10px;
}
```

## Variables

Syntax: `<property>-<value>[--componentName]`

Variable names in our CSS are also strictly structured. This syntax provides strong associations between property, use, and component.

The following variable defintion is a color property, with the value grayLight, for use with the highlightMenu component.

```css
@color-grayLight--highlightMenu: rgb(51, 51, 50);
```

### Colours

When implementing feature styles, you should only be using color variables provided in `colors.scss`.

When adding a color variable to `colors.scss`, using RGB and RGBA color units are preferred over hex, named, HSL, or HSLA values.

**Right:**

```css
rgb(50, 50, 50);
rgba(50, 50, 50, 0.2);
```

**Wrong:**

```css
#FFF;
#FFFFFF;
white;
hsl(120, 100%, 50%);
hsla(120, 100%, 50%, 1);
```

### z-index

You should never directly set a z-index value. Please use the z-index scale defined in `z-index.scss`.

`@zIndex-1` - `@zIndex-9` are provided. Nothing should be higher then `@zIndex-9`.

## Components

Always look to abstract components. A name like `.homepage-nav` limits its use. Instead think about writing styles in such a way that they can be reused in other parts of the app. Instead of `.homepage-nav`, try instead `.nav` or `.nav-bar`. Ask yourself if this component could be reused in another context (chances are it could!).

Components should belong to their own Sass file. For example, all general button definitions should belong in buttons.scss.

Component driven development offers several benefits when reading and writing HTML and CSS:

* It helps to distinguish between the classes for the root of the component, descendant elements, and modifications.
* It keeps the specificity of selectors low.
* It helps to decouple presentation semantics from document semantics.

You can think of components as custom elements that enclose specific semantics, styling, and behaviour.

## Semantics

We want to keep our CSS classes semantic so that the styles have some meaning and clear reasoning behind why they exist.

**Right**:

```css
.content {
  ...
}
```

**Wrong**:

```css
.wrapper {
  ...
}
```

### Grids

Grid systems have a tendency to fill the DOM with unsemantic selectors, and as such we use [Neat](http://neat.bourbon.io), a set of mixins that removes the need to have grid-related selectors in the DOM.

## Performance

### Specificity

Although it is in the name (cascading style sheets), cascading can introduce unnecessary performance overhead for applying styles. Take the following example:

```css
ul.user-list li span a:hover { color: red; }
```

Styles are resolved during the renderer's layout pass. The selectors are resolved right to left, exiting when it has been detected the selector does not match. Therefore, in this example every `a` tag has to be inspected to see if it resides inside a `span` and an `li`. As you can imagine this requires a lot of DOM walking and and for large documents can cause a significant increase in the layout time. For further reading checkout: https://developers.google.com/speed/docs/best-practices/rendering#UseEfficientCSSSelectors and this [great talk on Github's CSS](https://speakerdeck.com/jonrohan/githubs-css-performance).

If we know we want to give all `a` elements inside the `.user-list` red on hover we can simplify this style to:

```css
.user-list > a:hover {
  color: red;
}
```

If we want to only style specific `a` elements inside `.user-list` we can give them a specific class:

```css
.user-list > .link-primary:hover {
  color: red;
}
```

## Clearfixes

You should almost never need to use a `.clearfix` element to solve your problems. [`overflow: hidden` is probably what you want](http://stackoverflow.com/a/5566093/245017).