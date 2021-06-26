### Site generate with collection

On the site generator configuration: we want to add an option/field, where
a user can provide collection file as configuration.

During site generation, we want the generator to take this into consideration
and based on this we also want to the site generator to invoke the collection
building happening.

In the collection interface, we also want to support configuration options,
instead of passing around we also want to be specified in form of data filed
and use that one to pass it down to the metanorma xml

### Todos

- [ ] Add support for collection option parsing
- [ ] Adopt the field changes for the collection
- [ ] Define collection config in the generator
- [ ] Invoke the parsing from the site generator
- [ ] Adopt this interface in collection, maybe?
