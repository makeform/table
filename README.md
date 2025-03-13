# @makeform/table

## Configs

 - `fields`: array of fields definition for fields to be used in this table.
 - `noHeader`: default false. hide table header if true.
 - `entryName`: default ''. name used when referring to a single entry in this table.
   - this will be used in places like button text such as "add entry", "add item", etc.

## Fields

`fields` in config is an array of widget definition object. it instructs how we should render and control the dynamics of each field. Each object contains following fields:

 - `type`: `@plotdb/block` style block identifier (bid) to indicate the widget to use. can also be a string such as `@makeform/input`.
 - `meta`: widget meta object. see `@plotdb/form` for more detail.


## License

MIT
