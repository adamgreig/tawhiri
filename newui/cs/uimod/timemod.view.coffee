UIMod.TimeMod.view = ->
        [
         # Launch time (local)
         (m '.form-group', [
            (m 'label.control-label.col-sm-4[for=inp-date]', 'Local Time'),
            (m '.col-sm-8',
                m 'input.form-control#inp-date
                   [required][type=text][placeholder="Click to set launch date"]',
                    value: ConfigVM.launch_time(),
                    onchange: m.withAttr('value', ConfigVM.launch_time),
                    config: (element, isInit, ctx) ->
                        $(element).datetimepicker
                            format: "HH:mm, D MMM YYYY",
                            format: "YYYY-MM-DD HH:mm",
                            stepping: 5,
                            minDate: new Date().setHours(0,0,0,0),
                            maxDate: Date.now() + 7*24*60*60*1000,
                            showTodayButton: true,
                            showClose: true,
                            sideBySide: true
                        $(element).bind 'dp.change', m.withAttr('value', ConfigVM.launch_time)
                ),
         ]),

         # Local time UTC Offset
         (m '.form-group', [
            (m 'label.control-label.col-sm-4[for=inp-tz]', 'UTC Offset'),
            (m '.col-sm-8', m '.input-group', [
                (m 'input.form-control#inp-tz[required][type=number]',
                    value: ConfigVM.time_offset(),
                    onchange: m.withAttr 'value', ConfigVM.time_offset
                ),
                (m 'span.input-group-addon', 'hours'),
            ]),
         ]),
        ]
