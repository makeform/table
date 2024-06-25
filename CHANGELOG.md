# Change Logs

## v1.2.4

 - add `no-data-cell` ld selector for programmatically deciding colspan for `no-data-cell` to prevent layout issue
 - explicitly set button cell size
 - use css class for adder-field and add css to prevent content overflow and interaction


## v1.2.3

 - make table layout fixed for consistent table cell size


## v1.2.2

 - ensure inner widget validated with `init:true` for not-yet-rendered widgets to prevent inconsistent validation status between inside and outside.


## v1.2.1

 - tweak error style
 - hide adder fields
 - deserialize only if needed
 - upgrade dependencies


## v1.2.0

 - use `新增` to replace `加入``
 - support `entry-name` selector


## v1.1.4

 - use `mf-note` to replace styling in note-related tag.
 - support `note` selector
 - add `m-edit` for error hint


## v1.1.3

 - fix bug: i18n change doesn't affect fixed content in `popup-input` 


## v1.1.2

 - add `desc` field.


## v1.1.1

 - remove label nowrap style to prevent form overflow to affect overall layout


## v1.1.0

 - add header block for information such as title, description and limitation.


## v1.0.4

 - tweak cell alignment to top


## v1.0.3

 - remove row block info to correctly support re-editing of a previously existed key


## v1.0.2

 - tweak margin after widget
 - upgrade dependencies to fix vulnerabilities


## v1.0.1

 - adder fields should be always optional, otherwise user may think those fields are also mandatory.


## v1.0.0

 - init release

