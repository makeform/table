module.exports =
  pkg:
    name: "@makeform/table", extend: {name: "@makeform/common"}
    dependencies: [
      {name: "ldcover"}
      {name: "ldcover", type: \css, global: true}
    ]
    i18n:
      en:
        "加入": "Add"
        "新增": "Add"
        "刪除": "Delete"
        "無資料": "No data"
      zh:
        "加入": "加入"
        "新增": "新增"
        "刪除": "刪除"
        "無資料": "無資料"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, parent, t, manager}) ->
  {ldview, ldcover} = ctx
  init: ->
    lc = @mod.child
    lc <<< data: [], editor: [], adder: {fields: []}, lastmeta: {}, isnew: {}
    @on \change, (v = []) ->
      lc.data = v
      lc.view.render!
    @on \mode, -> @mod.child.view.render!
    value-to-widget = ~>
      @value lc.data .then ~>
        lc.view.render!
        # for rendering common fields such as error
        @mod.info.view.render!
    getkey = @mod.child.getkey = (o, i) -> o.alias or o.key or o.title or i

    # - we need to wait for all fields initialized so validation can correctly validate all newly added fields
    # - yet we also need DOM for initing them which depends on ldview
    # - but ldview dont support waiting for init in subview
    # so we have to workaround with proxise which resolved when all fields initialized.
    wait-for-fields = (host) ->
      host.proxise = px = proxise (v) ->
        if Array.isArray(v) => return px <<< _list: v, _hash: {}
        if v in px.[]_list => px._hash[v] = true
        if px._list.filter(->!px._hash[it]).length => return
        px.resolve!
        return Promise.resolve!
      host.proxise host.list.map(->it.key)
    @mod.child.view = new ldview do
      root: root
      init: "popup-input": ({node}) ->
        # we set `in-place` to true so block transformation works for content in it.
        lc.popup-input = new ldcover root: node, resident: true, in-place: true
      action: click:
        "popup-input-toggle": ~>
          if @mod.info.meta.readonly => return
          lc.popup-input.get!
        add: ({views}) ~>
          if @mod.info.meta.readonly => return
          lc.data.push new-row = {
            list: @mod.info.config.fields.map (d,i) ->
              key = getkey(d,i)
              key: key
              value: lc.adder.fields[key].itf.value!
            key: Math.round(Date.now! + Math.random! * 0xffff)toString(36)substring(2)
          }
          p = wait-for-fields(new-row)
          # we need to render between p above and then below
          # so init in subview can resolve our proxise
          views.0.render!
          p
            .then ~>
              # clean all `add` fields
              @mod.info.config.fields.map (d,i) ->
                lc.adder.fields[getkey(d,i)].itf.value null
              # update new-row to table value
              value-to-widget!
              views.0.render!

      handler:
        "popup-input-toggle": ({node}) ~>
          node.classList.toggle \disabled, !!@mod.info.meta.readonly
        "add": ({node}) ~>
          node.classList.toggle \disabled, !!@mod.info.meta.readonly
        "entry-name": ({node}) ~>
          n = @mod.info.meta.config.entry-name
          node.innerText = if !n => '' else t(n)
        "no-data": ({node}) ->
          node.classList.toggle \d-none, (lc.data and lc.data.length)
        "no-data-cell": ({node}) ~>
          node.setAttribute \colspan, (@mod.info.config.fields.length + 1)
        headers: ({node}) ~> node.classList.toggle \d-none, !!@mod.info.config.no-header
        head:
          list: ~> @mod.info.config.fields.map (d,i) -> {cfg: d, key: getkey(d,i)}
          key: -> it.key
          text: ({data}) -> t (data.cfg.meta.title or 'untitled')

        row:
          list: -> lc.data
          key: -> it.key
          view:
            init: t: ({node}) -> node.setAttribute \t, node.innerText
            action: click: delete: ({views, ctx}) ~>
              if @mod.info.meta.readonly => return
              lc.editor[ctx.key] = null
              idx = lc.data.map(->it.key).indexOf(ctx.key)
              if idx == -1 => return
              lc.data.splice idx, 1
              value-to-widget!
              views.1.render!
            text: t: ({node}) -> node.innerText = t(node.getAttribute \t)
            handler:
              delete: ({node}) ~> node.classList.toggle \disabled, !!@mod.info.meta.readonly
              "editor-field":
                list: ({ctx}) -> ctx.list
                key: -> it.key
                view:
                  init: "@": ({node, ctx, ctxs}) ~>
                    map = @mod.child.metamap
                    {type, meta} = map[ctx.key] or {}
                    if !meta => return
                    # any exception in other handler lead to incorrect re-init into here
                    # and recall of manager.from cause a re-render by itf.on change,
                    # leading to a infinite rendering.
                    # so, for now we only reinit if following field is not defined.
                    if lc.editor{}[ctxs.0.key][ctx.key] => return
                    manager.from {name: type}, {root: node, data: meta}
                      .then (o) ~>
                        {bi, itf} = lc.editor{}[ctxs.0.key][ctx.key] = {bi: o.instance, itf: o.interface}
                        lc.isnew{}[ctxs.0.key][ctx.key] = true
                        if @mod.child.host =>
                          itf.adapt({
                            upload: ({file, progress}) ~>
                              @mod.child.host.upload({file, progress, alias: meta.title})
                          })
                        itf.value ctx.value
                        itf.on \change, ->
                          # lc.data may be overwritten so we have to lookup our object again
                          row = lc.data.filter(-> it.key == ctxs.0.key).0 or {}
                          col = row.[]list.filter(-> it.key == ctx.key).0
                          if !col => return
                          col.value = itf.value!
                          value-to-widget!
                        # report block initialized
                        if ctxs.0.proxise => that ctx.key
                  handler: "@": ({ctx, ctxs}) ~>
                    map = @mod.child.metamap
                    lastmap = @mod.child.lastmeta
                    isnew = @mod.child.isnew
                    if !(editor = lc.editor{}[ctxs.0.key][ctx.key]) => return
                    if !editor.itf => return
                    meta = {} <<< (map[ctx.key].meta or {}) <<< {readonly: @mod.info.meta.readonly}
                    strmeta = JSON.stringify(meta)
                    lastmeta = lastmap{}[ctxs.0.key][ctx.key]
                    lastmap[ctxs.0.key][ctx.key] = strmeta
                    Promise.resolve!
                      .then ->
                        if strmeta == lastmeta => return
                        isnew{}[ctxs.0.key][ctx.key] = false
                        editor.itf.deserialize meta, {init:true}
                      .then ~>
                        editor.bi.transform \i18n
                        editor.itf.value ctx.value, {from-source: true}
                      .then ~>
                        # we used to forec validate here, because we deserialize widget every time,
                        # and deserialize re-validate with init: true, thus reset validate result.
                        # however, we now skip deserialize if meta not changed, so this becomes unnecessary.
                        # editor.itf.validate!
                        editor.itf.mode @mode!

        "adder-field":
          list: ~> @mod.info.config.fields.map (d,i) -> {cfg: d, key: getkey(d,i)}
          key: (o) -> o.key
          view:
            init:
              "@": ({ctx, node}) ->
                {type, meta} = ctx.cfg
                ctx.cfg._meta = meta = ({} <<< meta or {}) <<< {is-required: false}
                manager.get name: (type or 'input')
                  .then (bc) -> bc.create!
                  .then (bi) -> bi.attach {root: node, data: meta} .then ->
                    lc.adder.fields[ctx.key] = {bi, itf: bi.interface!}

            handler:
              "@": ({ctx}) ~>
                {bi, itf} = lc.adder.fields[ctx.key] or {}
                if !itf => return
                if @mod.child.host =>
                  # table adapt may not yet called when we init. so we call itf adapt here.
                  itf.adapt({
                    upload: ({file, progress}) ~>
                      @mod.child.host.upload({file, progress, alias: ctx.cfg.meta.title})
                  })
                itf.deserialize({} <<< ctx.cfg._meta <<< {readonly: @mod.info.meta.readonly})
                  .then ->
                    bi.transform \i18n
                    itf.render!
  render: ->
    @mod.child.metamap = Object.fromEntries(@mod.info.config.fields.map (o,i) ~> [@mod.child.getkey(o,i) ,o])
    @mod.child.view.render!
  adapt: (opt) ->
    @mod.child.host = opt
    @render!
  is-empty: (v) -> !Array.isArray(v) or !v.length
  validate: (opt = {}) ->
    itfs = []
    if @mod.info.meta.is-required and @is-empty! =>
      @_errors = ["required"]
      @status if opt.init => 1 else 2
      @render!
      return Promise.resolve(@_errors)
    @mod.child.data.map (r) ~> r.list.map (d) ~>
      if @mod.child.editor{}[r.key][d.key] => itfs.push {itf: that.itf, isnew: @mod.child.isnew{}[r.key][d.key]}
    # non-init validate before isnew is cleared will cause invalidate status for this table
    # in this case, no errro hint in internal fields but table itself shows error,
    # which causes confusion to users. thus, we use isnew to determine a uninited field status
    # and force init: true when validating them.
    Promise.all(itfs.map (o) ~> o.itf.validate(opt <<< {init: o.isnew or opt.init}))
      .then ~>
        s = (Math.max.apply Math, itfs.map (o) -> o.itf.status!) >? 1
        if !opt.init and s == 1 =>
          s = if @mod.info.is-required => 2 else 0
        @status s
        return @_errors = (if s == 2 => ["error"] else [])
