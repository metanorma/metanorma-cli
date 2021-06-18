In the CLI implementation today we cannot build a metanorma collection.

This is how we do it now:

```sh
bundle exec metanorma site generate . -o published -c collection.yml
bundle exec metanorma collection si-brochure-bilingual.yml -x xml,html,presentation,pdf -w bilingual-brochure -c collection_cover.html
```

The second line builds a metanorma collection using the config file
si-brochure-bilingual.yml.

I believe we can integrate this command into the configuration file for site
generate. We might even want to clarify the roles of the commands: compile,
collection and site so they have different functions.

---
Agreed. I would further add that the collection YAML (si-brochure-bilingual.yml)
and the site YAML (collection.yml) MUST be kept separate: it would be a mistake
to bind them tightly. The file name of the collection YAML should be one of the
entries in the site YAML.

---

Here's an example from bipm-si-brochure. In si-brochure-bilingual.yml, you can see a number of options have been moved from the command line into an option in this YAML.

https://github.com/metanorma/bipm-si-brochure/blob/87446b21470e0edc3625e89bcc01d93fe389263f/metanorma.yml#L57-L61

```yaml
---
metanorma:
  source:
    files:
...
    - sources/si-brochure-en.adoc
    - sources/si-brochure-fr.adoc

    # The Collection
    - sources/si-brochure-bilingual.yml

  collection:
    organization: "BIPM - Bureau International des Poids et Mesures"
    name: "SI Brochure edition 9, semantic encoded version"
```

https://github.com/metanorma/bipm-si-brochure/blob/b2c8a441e2b8e77abf8026f194f256b535e5494a/sources/si-brochure-bilingual.yml#L1-L60

```yml
directives:
  - documents-inline

bibdata:
  title:
    - language: en
      content: The International System of Units (SI)
    - language: fr
      content: Le Système international d’unités (SI)
  type: collection
  docid:
    type: bipm
    id: sibrochure
  edition: 9
  date:
    - type: updated
      value: 2019-05-20
  copyright:
    owner:
      name: Bureau International des Poids et Mesures
      abbreviation: BIPM
    from: 2019

# TODO, was CLI option, not yet supported
output_dir: bilingual-brochure

# TODO, was CLI option, not yet supported
formats:
  - xml
  - html
  - presentation
  - pdf

manifest:
  level: brochure
  title: Brochure/Brochure

  # TODO, not yet supported
  # Option 1, specify built files
  # Option 2, specify source if not built
  documents:  # was `docref`
    - source: si-brochure-fr.adoc
      identifier: si-brochure-fr

      # was `fileref`
      rendered: site/documents/si-brochure-fr.xml

    - identifier: si-brochure-en
      source: si-brochure-en.adoc
      rendered: site/documents/si-brochure-en.xml

# TODO, was CLI option, not yet supported
cover: collection_cover.html

prefatory-content:
|


final-content:
|
```

Desired compile command:
* `metanorma site generate` to generate all documents + collection (since the yaml is specified in path)
* `metanorma si-brochure-bilingual.yml`
