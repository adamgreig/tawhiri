SavedLocation = (data) ->
    this.latitude = m.prop data.latitude
    this.longitude = m.prop data.longitude
    this.altitude = m.prop data.altitude
    this.name = m.prop data.name
    return

ConfigVM =
    init: ->
        ConfigVM.load_saved_locations()
        $(window).bind 'storage', ->
            ConfigVM.load_saved_locations()
            m.redraw.strategy 'diff'
            m.redraw()

        ConfigVM.latitude = m.prop ''
        ConfigVM.longitude = m.prop ''
        ConfigVM.altitude = m.prop ''
        ConfigVM.location_name = m.prop ''
        ConfigVM.launch_time = m.prop ''
        ConfigVM.time_offset = m.prop (new Date()).getTimezoneOffset()/60
        ConfigVM.mode = m.prop 'Standard'
        ConfigVM.burst_alt = m.prop ''
        ConfigVM.float_alt = m.prop ''
        ConfigVM.payload_mass = m.prop ''
        ConfigVM.bfp_key = m.prop ''
        ConfigVM.bfp_val = m.prop ''
        ConfigVM.balloon_mass = m.prop ''
        ConfigVM.balloon_cd = m.prop 0.25
        ConfigVM.balloon_bd = m.prop ''
        ConfigVM.ascent_rate = m.prop ''

    load_saved_locations: ->
        ConfigVM.saved_locations = new Object()
        if localStorage.getItem 'saved_locations'
            ConfigVM.saved_locations[n] = new SavedLocation(d) for n, d of JSON.parse localStorage.getItem 'saved_locations'
        else
            ConfigVM.saved_locations['Cambridge, UK'] = new SavedLocation
                latitude: 52.2135, longitude: 0.0964, altitude: 14, name: "Cambridge, UK"
            ConfigVM.store_saved_locations()

    store_saved_locations: ->
        localStorage.setItem 'saved_locations', JSON.stringify ConfigVM.saved_locations

    save_location: ->
        [lat, lng, alt, name] = [
            ConfigVM.latitude, ConfigVM.longitude,
            ConfigVM.altitude, ConfigVM.location_name]
        if lat() and lng() and name()
            ConfigVM.saved_locations[name()] = new SavedLocation
                latitude: lat(), longitude: lng(),
                altitude: alt(), name: name()
            ConfigVM.store_saved_locations()

    load_location: ->
        name = this.innerHTML
        if name of ConfigVM.saved_locations
            sl = ConfigVM.saved_locations[name]
            ConfigVM.latitude(sl.latitude())
            ConfigVM.longitude(sl.longitude())
            ConfigVM.altitude(sl.altitude())
            ConfigVM.location_name(sl.name())
        else
            # TODO actual error handling/warning displays
            alert 'Unknown location name'

    delete_location: ->
        if ConfigVM.location_name() of ConfigVM.saved_locations
            delete ConfigVM.saved_locations[ConfigVM.location_name()]
            ConfigVM.store_saved_locations()
            ConfigVM.location_name ''
        else
            # TODO actual error handling/warning displays
            alert 'Unknown location name'

    get_gps_location: ->
        if "geolocation" of navigator
            navigator.geolocation.getCurrentPosition (position) ->
                ConfigVM.latitude(position.coords.latitude)
                ConfigVM.longitude(position.coords.longitude)
                ConfigVM.altitude(position.coords.altitude)
                m.redraw.strategy 'diff'
                m.redraw()
                console.log "Received geolocation position ", position
        else
            # TODO proper errors
            alert "Geolocation not available"


UIMod = {}

UIMod.LocationMod =
    controller: ->
        return
    view: ->
        [

         # Search bar
         (m '.form-group',
            m '.col-sm-12',
                m '.input-group', [
                    (m 'span.input-group-btn',
                        m 'button.btn.btn-info#gps-locate[type=button][title="use GPS location"]',
                            onclick: ConfigVM.get_gps_location,
                            m 'span.glyphicon.glyphicon-globe'),
                    (m 'input.form-control#pac-input[type=text][placeholder="Right click map or search"][autocomplete=off]'),
                    (m 'span.input-group-btn',
                        m 'button.btn.btn-default#pac-input-submit[type=button]',
                            m 'span.glyphicon.glyphicon-search'),
                ]),

         # Latitude
         (m '.form-group', [
            (m 'label.control-label.col-sm-4[for=inp-launch-lat]', 'Latitude'),
            (m '.col-sm-8',
                m 'input.form-control#inp-launch-lat[required][type=number][placeholder="dd.dddd"]',
                    value: ConfigVM.latitude(),
                    onchange: m.withAttr 'value', ConfigVM.latitude
                ),
         ]),

         # Longitude
         (m '.form-group', [
            (m 'label.control-label.col-sm-4[for=inp-launch-lng]', 'Longitude'),
            (m '.col-sm-8',
                m 'input.form-control#inp-launch-lng[required][type=number][placeholder="dd.dddd"]',
                    value: ConfigVM.longitude(),
                    onchange: m.withAttr 'value', ConfigVM.longitude
                ),
         ]),

         # Altitude
         (m '.form-group', [
             (m 'label.control-label.col-sm-4[for=inp-launch-alt]', 'Altitude'),
             (m '.col-sm-8', m '.input-group', [
                (m 'input.form-control#inp-launch-alt[required][step=any][type=number][placeholder="ASL"]',
                    value: ConfigVM.altitude(),
                    onchange: m.withAttr 'value', ConfigVM.altitude
                ),
                (m '.input-group-btn.unit-selector', [
                    (m 'button.btn.btn-default.dropdown-toggle[type=button][data-toggle=dropdown]',
                        (m 'span.current-unit', 'm')),
                    (m 'ul.dropdown-menu.dropdown-menu-right.dropdown-menu-units', [
                        (m 'li', m 'a[href=#]', 'm'), (m 'li', m 'a[href=#]', 'ft') ]),
                ]),
            ]),
         ]),

         # Location Name
         (m '.form-group', [
             (m 'label.control-label.col-sm-4[for=inp-loc-name]', 'Name'),
             (m '.col-sm-8', m '.input-group', [
                (m 'input.form-control#inp-loc-name[type=text][autocomplete=off][placeholder="\"Best Launch Site\""]',
                    value: ConfigVM.location_name(),
                    onchange: m.withAttr 'value', ConfigVM.location_name
                ),
                (m '.input-group-btn', [
                    (m 'button.btn.btn-default.dropdown-toggle[type=button][data-toggle=dropdown]',
                        m 'span.caret'),
                    (m 'ul.dropdown-menu.dropdown-menu-right',
                        #(ConfigVM.saved_locations.map (sl) ->
                            #m 'li', m 'a[href=#]', onclick: ConfigVM.load_location, sl.name()
                        ((m 'li', m 'a[href=#]', onclick: ConfigVM.load_location, name) for name, data of ConfigVM.saved_locations
                        ).concat [
                            (m 'li.divider'),
                            (m 'li', m 'a[href=#]', onclick: ConfigVM.save_location, [(m 'span.glyphicon.glyphicon-save'), (' Save')]),
                            (m 'li', m 'a[href=#]', onclick: ConfigVM.delete_location, [(m 'span.glyphicon.glyphicon-trash'), (' Delete')]),
                        ]
                    ),
                ]),
            ]),
         ]),
        ]

UIMod.TimeMod =
    controller: ->
        return
    view: ->
        [
         # Launch time (local)
         (m '.form-group', [
            (m 'label.control-label.col-sm-4[for=inp-date]', 'Local Time'),
            (m '.col-sm-8',
                m 'input.form-control#inp-date[required][type=text][placeholder="Click to set launch date"]',
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

UIMod.BalloonMod =
    controller: ->
        return
    view: ->
        [
         # Mode
         (m '.form-group', [
             (m 'label.control-label.col-sm-4[for=inp-mode]', 'Mode'),
             (m '.col-sm-8', [
                 (m '.btn-group', [
                     (m 'button.btn.btn-default.dropdown-toggle[type=button][data-toggle=dropdown][aria-expanded=false]', ['Standard ', m 'span.caret']),
                     (m 'ul.dropdown-menu[role=menu]', [
                         (m 'li', m 'a[href=#]', 'Standard'),
                         (m 'li', m 'a[href=#]', ['Standard ', m.trust('&plusmn;'), '% scatter']),
                         (m 'li', m 'a[href=#]', 'Standard min-max scatter'),
                         (m 'li', m 'a[href=#]', 'Hourly'),
                     ]),
                 ]),
                 ' ',
                 (m 'button.btn.btn-default[type=button][title="Choose hours for hourly prediction"]',
                    m 'span.glyphicon.glyphicon-time'),
             ]),
         ]),
         
         # Burst Alt / Float Alt / Payload Mass
         (m '.form-group', [
             (m '.col-sm-4', m '.btn-group', [
                 (m 'button.btn.btn-default.dropdown-toggle.dropdown-label[type=button][data-toggle=dropdown][aria-expanded=false]', 'Burst Alt'),
                 (m 'ul.dropdown-menu[role=menu]', [
                     (m 'li', m 'a[href=#]', 'Burst Alt'),
                     (m 'li', m 'a[href=#]', 'Float Alt'),
                     (m 'li', m 'a[href=#]', 'Payload Mass'),
                 ]),
             ]),
             (m '.col-sm-8', m '.input-group', [
                 (m 'input.form-control#inp-bfp-val[required][type=number][step=any]',
                    value: ConfigVM.bfp_val(),
                    onchange: m.withAttr 'value', ConfigVM.bfp_val
                 ),
                 (m '.input-group-btn', [
                     (m 'button.btn.btn-default.dropdown-toggle[type=button][data-toggle=dropdown]', ['km ', m.trust('&plusmn;'), '10% ', m 'span.caret']),
                     (m 'ul.dropdown-menu.dropdown-menu-right.dropdown-menu-units', [
                         (m 'li', m 'a[href=#]', 'km'),
                         (m 'li', m 'a[href=#]', 'kft'),
                         (m 'li.divider'),
                         (m 'li', m 'a[href=#]', m.trust('&plusmn;0%')),
                         (m 'li', m 'a[href=#]', m.trust('&plusmn;5%')),
                         (m 'li', m 'a[href=#]', m.trust('&plusmn;10%')),
                         (m 'li', m 'a[href=#]', m.trust('&plusmn;15%')),
                         (m 'li', m 'a[href=#]', m.trust('&plusmn;20%')),
                     ]),
                 ]),
             ]),
         ]),

         # Balloon choice
         (m '.form-group', [
             (m 'label.control-label.col-sm-4[for=inp-bm]', 'Balloon'),
             (m '.col-sm-8', m '.input-group', [
                 (m 'button.btn.btn-default.dropdown-toggle[type=button][data-toggle=dropdown][disabled]', 'Hwoyee 600g'),
                 (m 'ul.dropdown-menu.dropdown-menu-right', [
                     (m 'li', m 'a[href=#]', 'Hwoyee 100g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 200g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 300g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 350g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 400g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 500g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 600g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 750g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 800g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 950g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1000g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1200g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1500g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 1600g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 2000g'),
                     (m 'li', m 'a[href=#]', 'Hwoyee 3000g'),
                 ]),
             ]),
         ]),

         # Ascent Rate / Burst Altitude
         (m '.form-group', [
             (m '.col-sm-4', m '.btn-group', [
                 (m 'button.btn.btn-default.dropdown-toggle.dropdown-label[type=button][data-toggle=dropdown][aria-expanded=false]', 'Ascent Rate'),
                 (m 'ul.dropdown-menu[role=menu]', [
                     (m 'li', m 'a[href=#]', 'Ascent Rate'),
                     #(m 'li', m 'a[href=#]', 'Burst Alt'),
                 ]),
             ]),
             (m '.col-sm-8', m '.input-group', [
                 (m 'input.form-control#inp-ar-min[required][type=number][placeholder=Min][step=any]'),
                 (m 'input.form-control#inp-ar-max[required][type=number][placeholder=Max][step=any]'),
                 (m '.input-group-btn.unit-selector', [
                     (m 'button.btn.btn-default.dropdown-toggle[data-toggle=dropdown][type=button]', [(m 'span.current-unit', 'm/s'), ' ', (m 'span.caret')]),
                     (m 'ul.dropdown-menu.dropdown-menu-right.dropdown-menu-units', [
                         (m 'li', m 'a[href=#]', 'm/s'),
                         (m 'li', m 'a[href=#]', 'ft/s'),
                     ]),
                 ]),
             ]),
         ]),
        ]

UIMod.controller = ->
    ConfigVM.init()

UIMod.view = ->
    m 'form.form-horizontal', [
        UIMod.LocationMod.view(),
        UIMod.TimeMod.view(),
        UIMod.BalloonMod.view(),
        m '.form-group',
            m '.col-sm-8.col-sm-offset-2',
                m 'button.btn.btn-lg.btn-success#runpred[type=button]', 'Run Prediction'
    ]

MapMod = {}

MapMod.MapVM =
    init: ->
        return

MapMod.controller = ->
    return

MapMod.view = ->
    m '.jumbotron', [
        (m 'h1', 'Map Goes Here'),
        (m 'p', '
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum
            quis diam eu eros laoreet elementum in vel ipsum. Maecenas congue
            viverra sem. Sed tempus pulvinar nunc, non pretium odio tempus
            vitae.  Phasellus gravida urna leo, et laoreet mauris tempus vitae.
            Curabitur porttitor volutpat ipsum in fermentum. Quisque laoreet
            nisl ut enim sodales, non sollicitudin nibh eleifend. Ut sagittis
            lorem in mauris scelerisque, in egestas metus maximus. 
         '),
    ]
    

InfoMod = {}

PredModel = {}

TawhiriApp = {}


# Debug/test bindings
this.SavedLocation = SavedLocation
this.ConfigVM = ConfigVM
this.UIMod = UIMod

# Bind UI Module to the sidebar
m.module document.getElementById('sidebar'),
    controller: UIMod.controller, view: UIMod.view

# Bind Map Module to the map element
m.module document.getElementById('map'),
    controller: MapMod.controller, view: MapMod.view
