
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
        ConfigVM.time_offset = m.prop -(new Date()).getTimezoneOffset()/60
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
        sl = localStorage.getItem 'saved_locations'
        if sl
            ConfigVM.saved_locations[n] = new SavedLocation(d) for n, d of JSON.parse sl
        else
            ConfigVM.saved_locations['Cambridge, UK'] = new SavedLocation
                latitude: 52.2135, longitude: 0.0964,
                altitude: 14, name: "Cambridge, UK"
            ConfigVM.store_saved_locations()

    store_saved_locations: ->
        localStorage.setItem('saved_locations',
            JSON.stringify ConfigVM.saved_locations)

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

