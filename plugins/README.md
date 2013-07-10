ArchivesSpace Plug-ins README
-----------------------------

Plug-ins provide a mechanism to customize ArchivesSpace by overriding or extending functions
without changing the core codebase. As they are self-contained, they also permit the ready
sharing of packages of customization between ArchivesSpace instances.


Plug-ins are enabled by placing them in the `plugins` directory, and referencing them in the
ArchivesSpace configuration, `common/config/config.rb`. For example:

    AppConfig[:plugins] = ['local', 'hello_world', 'my_plugin']

This configuration assumes the following directories exist:

    plugins
      hello_world
      local
      my_plugin

Note that the order that the plug-ins are listed in the `:plugins` configuration option
determines the order in which they are loaded by the application.

The directory structure within a plug-in is similar to the structure of the core application.
The following shows the supported plug-in structure. Files contained in these directories can
be used to override or extend the behavior of the core application.

    backend
      controllers .... backend endpoints
      model .......... database mapping models
    frontend
      assets ......... static assets (such as images, javascript) in the staff interface
      controllers .... controllers for the staff interface
      locales ........ locale translations for the staff interface
      views .......... templates for the staff interface
    public
      assets ......... static assets (such as images, javascript) in the public interface
      controllers .... controllers for the public interface
      locales ........ locale translations for the public interface
      views .......... templates for the public interface
    migrations ....... database migrations
    schemas .......... JSONModel schema definitions

It is not necessary for a plug-in to have all of these directories. For example, to override
some part of a locale file for the staff interface, you can just add the following structure
to the local plug-in:

    plugins/local/frontend/locales/en.yml

This is a general rule. That is, to override behavior, rather then extend it, match the path
to the file that contains the behavior to be overridden. Another example, to override the
branding of the staff interface, add your own template at:

    plugins/local/frontend/views/site/_branding.html.erb

Files such as images, stylesheets and PDFs can be made available as static resources by
placing them in an `assets` directory under an enabled plug-in. For example, the following file:

    plugins/local/frontend/assets/my_logo.png

Will be available via the following URL:

    http://your.frontend.domain.and:port/assets/my_logo.png


Plug-ins can optionally contain a configuration file at `plugins/[plugin-name]/config.yml`.
This configuration file supports the following options:

    system_menu_controller
      The name of a controller that will be accessible via a Plug-ins menu in the System toolbar
    repository_menu_controller
      The name of a controller that will be accessible via a Plug-ins menu in the Repository toolbar
    parents
      [record-type]
        name
        cardinality
      ...

`system_menu_controller` and `repository_menu_controller` specify the names of frontend controllers
that will be accessible via the system and repository toolbars respectively. A `Plug-ins` dropdown
will appear in the toolbars if any enabled plug-ins have declared these configuration options. The
controller name follows the standard naming conventions, for example:

    repository_menu_controller: hello_world

Points to a controller file at `plugins/hello_world/frontend/controllers/hello_world_controller.rb`
which implements a controller class called `HelloWorldController`. When the menu item is selected
by the user, the `index` action is called on the controller.

Note that the URLs for plug-in controllers are scoped under `plugins`, so the URL for the above
example is:

    http://your.frontend.domain.and:port/plugins/hello_world

Also note that the translation for the plug-in's name in the `Plug-ins` dropdown menu is specified
in a locale file in the `frontend/locales` directory in the plug-in. For example, in the `hello_world`
example there is an English locale file at:

    plugins/hello_world/frontend/locales/en.yml

The translation for the plug-in name in the `Plug-ins` dropdown menus is specified by the key `label`
under the plug-in, like this:

    en:
      plugins:
        hello_world:
          label: Hello World

Note that the example locale file contains other keys that specify translations for text displayed
as part of the plug-in's user interface. Be sure to place your plug-in's translations as shown, under
`plugins.[your_plugin_name]` in order to avoid accidentally overriding translations for other
interface elements. In the example above, the translation for the `label` key can be referenced
directly in an erb view file as follows:

    <%= I18n.t("plugins.hello_world.label") %>

Each entry under `parents` specifies a record type that this plug-in provides a new subrecord for.
`[record-type]` is the name of the existing record type, for example `accession`. `name` is the
name of the plug-in in its role as a subrecord of this parent, for example `hello_worlds`.
`cardinality` specifies the cardinality of the plug-in records. Currently supported values are
`zero-to-many` and `zero-to-one`.


Please refer to the `hello_world` exemplar plug-in to find out more about how to implement
a plug-in. Be sure to test your plug-in thoroughly as it may have unanticipated impacts on your
ArchivesSpace application. Plug-ins are a powerful feature, designed to allow you to change
most aspects of how the application behaves.