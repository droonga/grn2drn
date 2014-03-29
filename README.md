# README

## Name

grn2drn

## Description

Grn2drn is a command to convert a *.grn dump file to a JSONs file for Droonga.

## Install

```
% gem install grn2drn
```

## Basic usage

For migrating Groonga to Droonga:

```
% grndump /path/to/groonga/database > dump.grn
% grn2drn --dataset Droonga dump.grn > droonga.jsons
```

You can send the converted data by `droonga-request` or `droonga-send`
command. They are included in
[droonga-client gem](http://rubygems.org/gems/droonga-client).


For creating [catalog.json](http://droonga.org/reference/catalog/):

```
% grndump --no-dump-tables /path/to/groonga/database > schema.grn
% grn2drn-schema schema.grn > schema.json
```

It generates JSON that can be embedded into catalog.json.

## Mailing list

* English: [groonga-talk@lists.sourceforge.net](https://lists.sourceforge.net/lists/listinfo/groonga-talk)
* Japanese: [groonga-dev@lists.sourceforge.jp](http://lists.sourceforge.jp/mailman/listinfo/groonga-dev)

## Thanks

* ...

## Copyright

Copyright (c) 2014 Droonga Project

## License

GPLv3 or later. See LICENSE.txt for details.
