UIMod.LocationMod.view = ->
        [

         # Search bar
         (m '.form-group',
            m '.col-sm-12',
                m '.input-group', [
                    (m 'span.input-group-btn',
                        m 'button.btn.btn-info#gps-locate
                           [type=button][title="use GPS location"]',
                            onclick: ConfigVM.get_gps_location,
                            m 'span.glyphicon.glyphicon-globe'),
                    (m 'input.form-control#pac-input
                        [type=text][placeholder="Right click map or search"]
                        [autocomplete=off]'),
                    (m 'span.input-group-btn',
                        m 'button.btn.btn-default#pac-input-submit
                           [type=button]',
                            m 'span.glyphicon.glyphicon-search'),
                ]),

         # Latitude
         (m '.form-group', [
            (m 'label.control-label.col-sm-4[for=inp-launch-lat]', 'Latitude'),
            (m '.col-sm-8',
                m 'input.form-control#inp-launch-lat
                   [required][type=number][placeholder="dd.dddd"]',
                    value: ConfigVM.latitude(),
                    onchange: m.withAttr 'value', ConfigVM.latitude
                ),
         ]),

         # Longitude
         (m '.form-group', [
            (m 'label.control-label.col-sm-4[for=inp-launch-lng]', 'Longitude'),
            (m '.col-sm-8',
                m 'input.form-control#inp-launch-lng
                   [required][type=number][placeholder="dd.dddd"]',
                    value: ConfigVM.longitude(),
                    onchange: m.withAttr 'value', ConfigVM.longitude
                ),
         ]),

         # Altitude
         (m '.form-group', [
             (m 'label.control-label.col-sm-4[for=inp-launch-alt]', 'Altitude'),
             (m '.col-sm-8', m '.input-group', [
                (m 'input.form-control#inp-launch-alt
                    [required][step=any][type=number][placeholder="ASL"]',
                    value: ConfigVM.altitude(),
                    onchange: m.withAttr 'value', ConfigVM.altitude
                ),
                (m '.input-group-btn.unit-selector', [
                    (m 'button.btn.btn-default.dropdown-toggle
                        [type=button][data-toggle=dropdown]',
                        (m 'span.current-unit', 'm')),
                    (m 'ul.dropdown-menu.dropdown-menu-right.dropdown-menu-units', [
                        (m 'li', m 'a[href=#]', 'm'),
                        (m 'li.disabled', m 'a[href=#]', 'ft') ]),
                ]),
            ]),
         ]),

         # Location Name
         (m '.form-group', [
             (m 'label.control-label.col-sm-4[for=inp-loc-name]', 'Name'),
             (m '.col-sm-8', m '.input-group', [
                (m 'input.form-control#inp-loc-name[type=text]
                    [autocomplete=off][placeholder="\"Best Launch Site\""]',
                    value: ConfigVM.location_name(),
                    onchange: m.withAttr 'value', ConfigVM.location_name
                ),
                (m '.input-group-btn', [
                    (m 'button.btn.btn-default.dropdown-toggle
                        [type=button][data-toggle=dropdown]',
                        m 'span.caret'),
                    (m 'ul.dropdown-menu.dropdown-menu-right',
                        ((m 'li', m 'a[href=#]', onclick: ConfigVM.load_location, name) for name, data of ConfigVM.saved_locations).concat [
                            (m 'li.divider'),
                            (m 'li', m 'a[href=#]', onclick: ConfigVM.save_location,
                                        [(m 'span.glyphicon.glyphicon-save'), (' Save')]),
                            (m 'li', m 'a[href=#]', onclick: ConfigVM.delete_location,
                                        [(m 'span.glyphicon.glyphicon-trash'), (' Delete')]),
                        ]
                    ),
                ]),
            ]),
         ]),
        ]
