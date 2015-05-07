TawhiriApp = {}


# Debug/test bindings
this.SavedLocation = SavedLocation
this.ConfigVM = ConfigVM
this.UIMod = UIMod

# Bind UI Module to the sidebar
m.mount document.getElementById('sidebar'),
    controller: UIMod.controller, view: UIMod.view

# Bind Map Module to the map element
m.mount document.getElementById('map'),
    controller: MapMod.controller, view: MapMod.view
